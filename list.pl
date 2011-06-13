#!/usr/bin/env perl

use strict;
use warnings;
use rlib 'lib';

use DailyArchive;
use DailyArchive::Tweet;
use DateTime::TimeZone;
use DateTime::Format::Natural;
use DateTime::Format::Pg;
use DateTime::Format::Strptime;
use JSON::XS ();
use Encode ();
#use Data::Printer;
use HTML::Entities ();
use Getopt::Long;

STDOUT->binmode(':utf8');
STDERR->binmode(':utf8');

# Various globals..
my $local_tz = DateTime::TimeZone->new(name => 'local');
my $nat_dt_parser = DateTime::Format::Natural->new( time_zone => 'local' );
my $pg_dt_parser = DateTime::Format::Pg->new();
my $rest_dt_parser = DateTime::Format::Strptime->new(pattern => '%a %b %d %T %z %Y');
my $human_dt_parser = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d %H:%M');
my $jp = JSON::XS->new->utf8;
my $da = DailyArchive->new();

# Process command line options
my $html;
my $opts = GetOptions(
    'html' => \$html,	# flag, use html output
);
my $input_date = shift @ARGV;

# Fetch date (today or natural date as command line arg)
my $dt = get_date($input_date);

print page_header(
    "Your daily tweets for " . $rest_dt_parser->format_datetime($dt)
);

# Fetch and display tweets for specified day
my $tweets = get_tweets(get_subscriber_id(), $dt);
if ( scalar @$tweets > 0 ) {
    print headline(
        scalar @$tweets . " tweet(s) found for " . $rest_dt_parser->format_datetime($dt)
    );
    print divider() unless $html;
    print format_tweets($tweets);
}
else {
    print headline(
        "No tweets found for " . $rest_dt_parser->format_datetime($dt)
    );
}

print page_footer();

exit;

# Format and return all the tweets according to formatting (plain text or HTML)
sub format_tweets {
    my ($tweets) = @_;
    my $output = "";
    $output .= qq!<ul class="tweets">\n! if $html;
    foreach my $tweet ( @$tweets ) {
        $output .= format_tweet($tweet);
    }
    $output .= "</ul>\n" if $html;
    return $output;
}

# The complete page header (mostly useful in HTML)
sub page_header {
    my ($title) = @_;
    if ( $html ) {
        my $encoded_title = HTML::Entities::encode($title);
        return <<"EOM";
<!DOCTYPE html>
<html>
<head>
<title>$encoded_title</title>
<style>
body { font-family: sans-serif; }
a { text-decoration: none; }
li.tweet { float: left; min-width: 15em; max-width: 25em; height: 10ex; border: 0.125em solid #ccc; overflow: hidden; border-radius: 0.5em; padding: 0.25em; background-color: #eee;margin: 0.125em; }
li.tweet:hover { overflow: auto; background-color: rgba(218, 236, 244, 0.9); }
.tweet .user_image { float: left; margin-right: 0.25em; margin-bottom: 0.25em; }
.tweet .date { font-style: italic; margin-right: 0.5em; white-space: nowrap; font-size: 0.8em; }
.tweet .author { font-weight: bold; margin-right: 0.5em; font-size: 0.8em; }
.tweet .message { }
.tweet .message .hashtag { }
.tweet .message .user_mention { }
.tweet .message .url { }
</style>
</head>
<body>
EOM
    }
    return "";
}

# The complete page footer (mostly useful in HTML)
sub page_footer {
    if ( $html )  {
        return "</body>\n"
             . "</html>\n";
    }
    return divider();
}

# Wrap any strings in a headline-like code chunk
sub headline {
    my $str = join("\n", map { defined $_ ? $_ : "" } @_ );
    if ($html) {
        return "<h1>" . HTML::Entities::encode($str) . "</h1>\n";
    }
    return $str . "\n";
}

# Prints a line dividing output
sub divider {
    return "<hr>\n" if $html;
    return ( "-" x 79 ) . "\n";
}

# Parse a natural date string, return DateTime object in local time zone
sub get_date {
    my ($date) = @_;
    return DateTime->now( time_zone => $local_tz ) unless $date;
    my $dt = $nat_dt_parser->parse_datetime($date);
    die("Invalid date: " . $nat_dt_parser->error . "\n") unless $nat_dt_parser->success;
    $dt->set_time_zone($local_tz);
    return $dt;
}

# Fetches the subscriber id associated with the current access token
sub get_subscriber_id {
    my $access_token = $da->twitter_access_token;
    my $subscriber_id;
    my $sth = $da->dbh->prepare('SELECT subscriber_id FROM subscriber WHERE access_token = ?');
    $sth->execute($access_token);
    ($subscriber_id) = $sth->fetchrow_array();
    die("No subscriber found for access_token $access_token\n") unless $subscriber_id;
    return $subscriber_id;
}

# Fetches tweets for the specified subscriber and date (oldest first)
sub get_tweets {
    my ($subscriber_id, $dt) = @_;
    my $dt_start = $dt->clone;
    $dt_start->truncate( to => 'day' );
    my $dt_end = $dt_start->clone;
    $dt_end->add( days => 1 );
    $dt_end->subtract( seconds => 1 );
    warn("Duration start: " . $pg_dt_parser->format_datetime($dt_start) . "\n") if $da->debug;
    warn("Duration end:   " . $pg_dt_parser->format_datetime($dt_end)   . "\n") if $da->debug;
    my $old_enable_utf8 = $da->dbh->{'pg_enable_utf8'};
    $da->dbh->{'pg_enable_utf8'}= 0;
    my $sth = $da->dbh->prepare('SELECT t.tweet FROM timeline tl JOIN tweet t ON tl.tweet_id=t.tweet_id WHERE tl.subscriber_id = ? AND tl.created_at BETWEEN ? AND ? ORDER BY tl.created_at');
    $sth->execute(
        $subscriber_id,
        $pg_dt_parser->format_datetime($dt_start),
        $pg_dt_parser->format_datetime($dt_end),
    );
    my @tweets;
    while(my ($tweet) = $sth->fetchrow_array() ) {
        my $decoded_tweet = eval { $jp->decode( $tweet ); };
        if ($@) {
            warn("Ignoring malformed tweet: $tweet: $@\n");
        }
        push @tweets, $decoded_tweet if $decoded_tweet;
    }
    $da->dbh->{'pg_enable_utf8'} = $old_enable_utf8;
    return wantarray ? @tweets : \@tweets;
}

sub format_tweet {
    my ($tweet) = @_;
#    print "Tweet: ", p($tweet), "\n";
#    print "\t" . join(",", keys %{$tweet}) . "\n";
    my $created_at = $rest_dt_parser->parse_datetime(
        $tweet->{'created_at'}
    );
    $created_at->set_time_zone($local_tz);
    $created_at->set_formatter($human_dt_parser);

    my $output = "";
    $output .= qq!<li class="tweet">! if $html;

    my $formatted_tweet = "";
    $formatted_tweet .= "<div>" if $html;

    my $tweet_obj = DailyArchive::Tweet->new( json => $tweet );

    my $author = $tweet_obj->user->screen_name;
    my $author_safe = HTML::Entities::encode($author);

    my $author_name = $tweet_obj->user->name;
    my $author_name_safe = HTML::Entities::encode($author_name);

    my $tweet_id = $tweet->{'id'};
    my $tweet_id_safe = HTML::Entities::encode($tweet_id);

    # Format user image
    if ( $html ) {
        my $image_url = HTML::Entities::encode(
            $tweet_obj->user->profile_image_url
        );
        $formatted_tweet .= qq!<a class="author" href="http://twitter.com/$author_safe/" title="Twitter homepage for $author_name_safe" target="_blank">!
                         .  qq!<img class="user_image" src="$image_url" width="48" height="48" alt="Image of $author_name_safe">!
                         .  qq!</a>!;
    }

    # Format date
    if ( $html ) {
        $formatted_tweet .= qq!<a class="date" href="http://twitter.com/$author_safe/status/$tweet_id_safe" target="_blank" title="Tweet permalink">!
                         .  $created_at
                         .  q!</a>!;
    }
    else {
        $formatted_tweet .= $created_at;
    }

    # Format username
    if ( $html ) {
        if ( $tweet_obj->is_retweet ) {
            my $orig_tweet_author = $tweet->{'retweeted_status'}{'user'}{'screen_name'};
            my $orig_tweet_author_safe = HTML::Entities::encode($orig_tweet_author);

            my $orig_tweet_author_name = $tweet->{'retweeted_status'}{'user'}{'name'};
            my $orig_tweet_author_name_safe = HTML::Entities::encode($orig_tweet_author_name);

            $formatted_tweet .= qq!<span class="author">!
                             .  qq!<a href="http://twitter.com/$author_safe/" target="_blank" title="Twitter homepage for $author_name_safe">$author_safe</a>!
                             .  " / "
                             . qq!<a href="http://twitter.com/$orig_tweet_author_safe/" target="_blank" title="Twitter homepage for $orig_tweet_author_name_safe">$orig_tweet_author_safe</a>!
                             .  qq!</span>!;
        }
        else {
            $formatted_tweet .= qq!<span class="author">!
                             .  qq!<a href="http://twitter.com/$author_safe/" target="_blank" title="Twitter homepage for $author_name_safe">$author_safe</a>!
                             .  qq!</span>!;
        }
    }
    else {
        if ( $tweet_obj->is_retweet ) {
            $formatted_tweet .= " <"
                             .  Encode::decode_utf8(
                                    $author . "/" . $tweet->{'retweeted_status'}{'user'}{'screen_name'}
                                )
                             .  ">";
        }
        else {
            $formatted_tweet .= " <"
                             .  Encode::decode_utf8($author)
                             . ">";
        }
    }

    $formatted_tweet .= "</div>\n" if $html;

    # Format message
    if ( $html ) {
        $formatted_tweet .= qq!<span class="message">! . $tweet_obj->text_html . qq!</span>!;
    }
    else {
        $formatted_tweet .= " " . $tweet_obj->text;
    }

    $output .= $formatted_tweet;
    $output .= qq!</li>! if $html;
    $output .= "\n";
    return $output;
}
