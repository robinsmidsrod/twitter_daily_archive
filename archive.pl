#!/usr/bin/env perl

use strict;
use warnings;
use rlib 'lib';

use DailyArchive;
use Data::Dumper qw(Dumper);
use Encode qw(decode_utf8);
use DateTime::Format::Strptime ();
use DateTime::Format::Pg ();

STDOUT->binmode(':utf8');

my $debug = shift @ARGV;

my $da = DailyArchive->new( debug => $debug );
my $nt = $da->twitter;
my $rest_dt_parser = DateTime::Format::Strptime->new(pattern => '%a %b %d %T %z %Y');
my $pg_dt_parser = DateTime::Format::Pg->new();
my $jp = JSON::XS->new->utf8;

eval {
    my $active_user = $nt->verify_credentials();
    add_subscriber($active_user);
    print 'Logged in as:'
        . ' [' . $active_user->{'id'} . ']'
        . ' ' . decode_utf8($active_user->{'name'})
        . ' (' . decode_utf8($active_user->{'screen_name'}) . ')'
        . "\n" if $da->debug;

    my $since_id = get_most_recent_tweet_id($active_user->{'id'});
    my %since = $since_id ? ( since_id => $since_id ) : ();
    print "Archiving tweets since: $since_id\n" if $since_id and $da->debug;

    my @statuses = @{ $nt->home_timeline({
        count => 200,
        include_entities => 1,
        include_rts => 1,
        %since,
    }) };
    for my $status ( @statuses ) {
        #print Dumper($status), "\n";
        my $new_tweet = add_tweet($status, $active_user)    ? 'Nt' : '  ';
        my $new_user  = add_user($status->{'user'})         ? 'Nu' : '  ';
        my $new_tl    = add_timeline($status, $active_user) ? 'Ntl' : '   ';
        print $new_tweet . $new_user . $new_tl
            . "[" . $status->{'id'} . "]"
            . " " . $status->{'created_at'}
            . " <" . decode_utf8($status->{'user'}{'screen_name'}) . ">"
            . " " . decode_utf8($status->{'text'})
            . "\n" if $da->debug;
    }
};
if ( $@ ) {
    print STDERR "Twitter error occured: $@\n";
}

# Try to add a subscriber, just continue on error
sub add_subscriber {
    my ($subscriber) = @_;
    my $rc = 0;
    eval {
        my $sth = $da->dbh->prepare('INSERT INTO subscriber (subscriber_id, username, subscriber, access_token, access_token_secret) VALUES (?,?,?,?,?)');
        $rc = $sth->execute(
            $subscriber->{'id'},
            decode_utf8( $subscriber->{'screen_name'} ),
            $jp->encode($subscriber),
            $da->twitter_access_token,
            $da->twitter_access_token_secret,
        );
    };
    if ( $@ ) {
        warn("add_subscriber: $@\n") unless $@ =~ m/duplicate key value violates unique constraint "subscriber_pkey" at/;
        return;
    }
    return $rc ? 1 : 0;
}

# Add tweet to database, just continue on error
sub add_tweet {
    my ($tweet, $subscriber) = @_;
    my $tweet_id = $tweet->{'id'};
    my $rc = 0;
    eval {
        my $sth = $da->dbh->prepare('INSERT INTO tweet (tweet_id, tweet) VALUES (?,?)');
        $rc = $sth->execute(
            $tweet_id,
            $jp->encode($tweet),
        );
    };
    if ( $@ ) {
        warn("add_tweet: $@\n") unless $@ =~ m/duplicate key value violates unique constraint "tweet_pkey" at/;
        return;
    }
    return $rc ? 1 : 0;
}

# Add user to database, just continue on error
sub add_user {
    my ($user) = @_;
    my $user_id = $user->{'id'};
    my $rc = 0;
    eval {
        my $sth = $da->dbh->prepare('INSERT INTO "user" (user_id, "user") VALUES (?,?)');
        $rc = $sth->execute(
            $user_id,
            $jp->encode($user),
        );
    };
    if ( $@ ) {
        warn("add_user: $@\n") unless $@ =~ m/duplicate key value violates unique constraint "user_pkey" at/;
        return;
    }
    return $rc ? 1 : 0;
}

# Add tweet to timeline for subscriber, just continue on error
sub add_timeline {
    my ($tweet, $subscriber) = @_;
    my $tweet_id = $tweet->{'id'};
    my $user_id = $tweet->{'user'}->{'id'};
    my $subscriber_id = $subscriber->{'id'};
    my $created_at     = $pg_dt_parser->format_datetime(
        $rest_dt_parser->parse_datetime($tweet->{'created_at'})
    );
    my $rc = 0;
    eval {
        my $sth = $da->dbh->prepare('INSERT INTO timeline (subscriber_id, tweet_id, user_id, created_at) VALUES (?,?,?,?)');
        $rc = $sth->execute(
            $subscriber_id,
            $tweet_id,
            $user_id,
            $created_at,
        );
    };
    if ( $@ ) {
        warn("add_timeline: $@\n") unless $@ =~ m/duplicate key value violates unique constraint "timeline_pkey" at/;
        return;
    }
    return $rc ? 1 : 0;
}

# Fetch the most recent tweet id in the database for the subscriber
# If not found, or error happens, go from start of time
sub get_most_recent_tweet_id {
    my ($subscriber_id) = @_;
    my $tweet_id;
    eval {
        my $sth = $da->dbh->prepare('SELECT tweet_id FROM timeline WHERE subscriber_id = ? ORDER BY created_at DESC LIMIT 1');
        $sth->execute($subscriber_id);
        ($tweet_id) = $sth->fetchrow_array();
    };
    if ( $@ ) {
        warn("get_most_recent_tweet_id: $@\n");
        return;
    }
    return $tweet_id ? $tweet_id : undef;
}
