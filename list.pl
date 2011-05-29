#!/usr/bin/env perl

use strict;
use warnings;
use rlib 'lib';

use DailyArchive;
use DateTime::Format::Natural;
use DateTime::Format::Pg;
use DateTime::Format::Strptime;
use JSON::XS ();
use Encode ();
use Data::Dumper qw(Dumper);

STDOUT->binmode(':utf8');
STDERR->binmode(':utf8');

# Various globals..
my $nat_dt_parser = DateTime::Format::Natural->new();
my $pg_dt_parser = DateTime::Format::Pg->new();
my $rest_dt_parser = DateTime::Format::Strptime->new(pattern => '%a %b %d %T %z %Y');
my $jp = JSON::XS->new->utf8;
my $da = DailyArchive->new();

# Fetch date (today or natural date as command line arg)
my $dt = get_date(shift @ARGV);

# Fetch and display tweets for specified day
my $tweets = get_tweets(get_subscriber_id(), $dt);
if ( scalar @$tweets > 0 ) {
    print scalar @$tweets . " tweet(s) found for " . $rest_dt_parser->format_datetime($dt) . "\n";
    print "-" x 79, "\n";
    foreach my $tweet ( @$tweets ) {
        display_tweet($tweet);
    }
}
else {
    print "No tweets found for " . $rest_dt_parser->format_datetime($dt) . "\n";
}

exit;

# Parse a natural date string
sub get_date {
    my ($date) = @_;
    return DateTime->now() unless $date;
    my $dt = $nat_dt_parser->parse_datetime($date);
    die("Invalid date: " . $nat_dt_parser->error . "\n") unless $nat_dt_parser->success;
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
    my $dt_start = $dt->clone; $dt_start->truncate( to => 'day' );
    my $dt_end = $dt_start->clone; $dt_end->add( days => 1 );
    warn("Duration start: $dt_start\n") if $da->debug;
    warn("Duration end:   $dt_end\n") if $da->debug;
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

sub display_tweet {
    my ($tweet) = @_;
#    print Dumper(keys %{$tweet});
    print $rest_dt_parser->parse_datetime($tweet->{'created_at'})
        . " <" . Encode::decode_utf8($tweet->{'user'}{'screen_name'}) . ">"
        . " " . Encode::decode_utf8($tweet->{'text'})
        . "\n";
}
