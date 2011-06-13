#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;
use Test::LongString;
use File::Slurp;
use JSON::XS;

use rlib;
use utf8;

BEGIN {
	use_ok("DailyArchive::Tweet");
};

# Verify user information
{
    my $json = read_file("t/data/tweet.json");
    my $tweet = DailyArchive::Tweet->new( raw_json => $json );
    isa_ok($tweet, 'DailyArchive::Tweet');
    can_ok($tweet, 'user');
    my $user = $tweet->user;
    isa_ok($user, 'DailyArchive::TwitterUser');
    can_ok($user, 'profile_image_url');
    is( $user->profile_image_url, "http://a0.twimg.com/profile_images/386937621/TwitterBugTEDTalks_normal.jpg", "First tweet user image url matches" );
    is( $user->screen_name, "tedtalks", "First tweet screen name matches" );
    is( $user->name, "TEDTalks Updates", "First tweet name matches" );
}
