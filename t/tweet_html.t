#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 60;
use Test::LongString;
use File::Slurp;
use JSON::XS;

use rlib;

BEGIN {
	use_ok("DailyArchive::Tweet");
};

my $tweet_file = read_file("t/data/tweet.json");
my $tweet2_file = read_file("t/data/tweet2.json");

is( length($tweet_file), 2078, "First raw tweet JSON data has correct length" );
is( length($tweet2_file), 1970, "Second raw tweet JSON data has correct length" );

my $tweet = JSON::XS::decode_json($tweet_file);
my $tweet2 = JSON::XS::decode_json($tweet2_file);

# Verify text is proper before we start
ok( exists $tweet->{'text'}, "First tweet has 'text' key" );
ok( exists $tweet2->{'text'}, "Second tweet has 'text' key" );
is( $tweet->{'text'}, "Today, a special #TED: Breaking the silence on suicide and suicide attempts: http://on.ted.com/JDSchramm More: http://t.co/wsNrY9C", "First tweet text matches" );
is( $tweet2->{'text'}, "Great Animoto vid of int'l couples traveling to NYC to get hitched. Thx \@bfreedphoto for this Vid of the Day: http://bitly.com/mej124 #VOD", "Second tweet text matches" );

# Verify entities are available before we start
ok( ( exists $tweet->{'entities'} and ref($tweet->{'entities'}) eq 'HASH' ), "First tweet has an 'entities' hash" );
ok( ( exists $tweet2->{'entities'} and ref($tweet2->{'entities'}) eq 'HASH' ), "Second tweet has an 'entities' hash" );
# Verify hashtags are available before we start
ok( ( exists $tweet->{'entities'}->{'hashtags'} and ref($tweet->{'entities'}->{'hashtags'}) eq 'ARRAY' ), "First tweet has an 'entities.hashtags' array" );
ok( ( exists $tweet2->{'entities'}->{'hashtags'} and ref($tweet2->{'entities'}->{'hashtags'}) eq 'ARRAY' ), "Second tweet has an 'entities.hashtags' array" );
# Verify user_mentions are available before we start
ok( ( exists $tweet->{'entities'}->{'user_mentions'} and ref($tweet->{'entities'}->{'user_mentions'}) eq 'ARRAY' ), "First tweet has an 'entities.user_mentions' array" );
ok( ( exists $tweet2->{'entities'}->{'user_mentions'} and ref($tweet2->{'entities'}->{'user_mentions'}) eq 'ARRAY' ), "Second tweet has an 'entities.user_mentions' array" );
# Verify urls are available before we start
ok( ( exists $tweet->{'entities'}->{'urls'} and ref($tweet->{'entities'}->{'urls'}) eq 'ARRAY' ), "First tweet has an 'entities.urls' array" );
ok( ( exists $tweet2->{'entities'}->{'urls'} and ref($tweet2->{'entities'}->{'urls'}) eq 'ARRAY' ), "Second tweet has an 'entities.urls' array" );

# Verify hashtag data in first tweet
{
    my $hashtags = $tweet->{'entities'}->{'hashtags'};
    is( scalar @$hashtags, 1, "First tweet has 1 hashtag" );
    is( $hashtags->[0]->{'text'}, 'TED', "That hashtag is 'TED'" );
    is( $hashtags->[0]->{'indices'}->[0], 17, "It starts at index 17" );
    is( $hashtags->[0]->{'indices'}->[1], 21, "Normal text continues at index 21" );
}

# Verify user_mentions in first tweet
{
    my $user_mentions = $tweet->{'entities'}->{'user_mentions'};
    is( scalar @$user_mentions, 0, "First tweet has 0 user mentions" );
}

# Verify urls in first tweet
{
    my $urls = $tweet->{'entities'}->{'urls'};
    is( scalar @$urls, 2, "First tweet has 2 urls" );
    is( $urls->[0]->{'url'}, 'http://on.ted.com/JDSchramm', "That url is 'http://on.ted.com/JDSchramm'" );
    is( $urls->[0]->{'expanded_url'}, undef, "That url doesn't expand to anything" );
    is( $urls->[0]->{'indices'}->[0], 77, "It starts at index 77" );
    is( $urls->[0]->{'indices'}->[1], 104, "Normal text continues at index 104" );
    is( $urls->[1]->{'url'}, 'http://t.co/wsNrY9C', "That url is 'http://t.co/wsNrY9C'" );
    is( $urls->[1]->{'expanded_url'}, 'http://wp.me/p10512-d9E', "That url expands to 'http://wp.me/p10512-d9E'" );
    is( $urls->[1]->{'display_url'}, 'wp.me/p10512-d9E', "Th expanded url displays as 'wp.me/p10512-d9E'" );
    is( $urls->[1]->{'indices'}->[0], 111, "It starts at index 111" );
    is( $urls->[1]->{'indices'}->[1], 130, "Normal text continues at index 130" );
}

# Verify hashtag data in second tweet
{
    my $hashtags = $tweet2->{'entities'}->{'hashtags'};
    is( scalar @$hashtags, 1, "Second tweet has 1 hashtag" );
    is( $hashtags->[0]->{'text'}, 'VOD', "That hashtag is 'VOD'" );
    is( $hashtags->[0]->{'indices'}->[0], 134, "It starts at index 134" );
    is( $hashtags->[0]->{'indices'}->[1], 138, "Normal text continues at index 138" );
}

# Verify user_mentions in second tweet
{
    my $user_mentions = $tweet2->{'entities'}->{'user_mentions'};
    is( scalar @$user_mentions, 1, "Second tweet has 1 user mention" );
    is( $user_mentions->[0]->{'id'}, 20490563, "And it has an id '20490563'" );
    is( $user_mentions->[0]->{'screen_name'}, 'bfreedphoto', "And it's screen name is 'bfreedphoto'" );
    is( $user_mentions->[0]->{'name'}, 'Brian Friedman', "And it's name is 'Brian Friedman'" );
    is( $user_mentions->[0]->{'indices'}->[0], 72, "It starts at index 72" );
    is( $user_mentions->[0]->{'indices'}->[1], 84, "Normal text continues at index 84" );
}

# Verify urls in second tweet
{
    my $urls = $tweet2->{'entities'}->{'urls'};
    is( scalar @$urls, 1, "Second tweet has 1 url" );
    is( $urls->[0]->{'url'}, 'http://bitly.com/mej124', "That url is 'http://bitly.com/mej124'" );
    is( $urls->[0]->{'expanded_url'}, undef, "That url doesn't expand to anything" );
    is( $urls->[0]->{'indices'}->[0], 110, "It starts at index 110" );
    is( $urls->[0]->{'indices'}->[1], 133, "Normal text continues at index 133" );
}

# Verify HTML generation of first tweet
{
    my $t1 = DailyArchive::Tweet->new( json => $tweet );
    isa_ok( $t1, 'DailyArchive::Tweet' );
    can_ok( $t1, 'text_html' );
    is_string(
        $t1->text_html,
        q!Today, a special <a class="hashtag" href="http://twitter.com/search/%23TED" title="Search Twitter for #TED" target="_blank">#TED</a>:!
      . q! Breaking the silence on suicide and suicide attempts: <a class="url" href="http://on.ted.com/JDSchramm" target="_blank">http://on.ted.com/JDSchramm</a>!
      . q! More: <a class="url" href="http://t.co/wsNrY9C" title="wp.me/p10512-d9E" target="_blank">http://t.co/wsNrY9C</a>!,
        "First tweet as HTML matches"
    );
}

# Verify HTML generation of second tweet
{
    my $t2 = DailyArchive::Tweet->new( raw_json => $tweet2_file );
    isa_ok( $t2, 'DailyArchive::Tweet' );
    can_ok( $t2, 'text_html' );
    is_string(
        $t2->text_html,
        q!Great Animoto vid of int&#39;l couples traveling to NYC to get hitched.!
      . q! Thx <a class="user_mention" href="http://twitter.com/bfreedphoto/" title="Twitter homepage for Brian Friedman" target="_blank">@bfreedphoto</a>!
      . q! for this Vid of the Day: <a class="url" href="http://bitly.com/mej124" target="_blank">http://bitly.com/mej124</a>!
      . q! <a class="hashtag" href="http://twitter.com/search/%23VOD" title="Search Twitter for #VOD" target="_blank">#VOD</a>!,
        "Second tweet as HTML matches"
    );
}

# Handle HTML entity escaping correctly (tweet3.json)
{
    my $tweet3_file = read_file("t/data/tweet3.json");
    my $t3 = DailyArchive::Tweet->new( raw_json => $tweet3_file );
    is_string( $t3->text, "shoes + Beach House music + Bokeh Masters Kit = cool  ==> http://flic.kr/p/91JLDM", "Third tweet 'text' matches" );
    is_string(
        $t3->text_html,
        q!shoes + Beach House music + Bokeh Masters Kit = cool  ==&gt; !
      . q!<a class="url" href="http://flic.kr/p/91JLDM" target="_blank">http://flic.kr/p/91JLDM</a>!,
        "Third tweet as HTML matches"
    );
}

# Handle retweets properly (tweet4.json)
{
    my $tweet4_file = read_file("t/data/tweet4.json");
    my $t4 = DailyArchive::Tweet->new( raw_json => $tweet4_file );
    is_string( $t4->text, "Barkley & LeBatard: If Mavs lose Barkley will wear a Speedo. If Heat lose, LeBatard wears Speedo. YOUR thoughts: http://bit.ly/kLnt8i", "Fourth tweet 'text' matches" );
    is_string(
        $t4->text_html,
        q!Barkley &amp; LeBatard: If Mavs lose Barkley will wear a Speedo. If Heat lose, LeBatard wears Speedo. YOUR thoughts: !
      . q!<a class="url" href="http://bit.ly/kLnt8i" target="_blank">http://bit.ly/kLnt8i</a>!,
        "Fourth tweet as HTML matches"
    );
}

# Handle retweet without any entities properly (tweet5.json)
{
    my $tweet5_file = read_file("t/data/tweet5.json");
    my $t5 = DailyArchive::Tweet->new( raw_json => $tweet5_file );
    is( scalar @{ $t5->_text_indices }, 1, "Fifth tweet has only 1 text index" ); # Implementation detail, do not use
    is( scalar @{ $t5->text_parts }, 1, "Fifth tweet has only 1 text part" );
    is(
        $t5->text_parts->[0],
        "DiCaprio neverdied in Titanic. last scene: going underwater. scene of Inception is him waking up on a beach."
      . "IT'S A MOVIE INSIDE A MOVIE O.O",
        "Fifth tweet has only one text part, content matches"
    );
    is_string(
        $t5->text,
        "DiCaprio neverdied in Titanic. last scene: going underwater. scene of Inception is him waking up on a beach."
      . "IT'S A MOVIE INSIDE A MOVIE O.O",
        "Fifth tweet 'text' matches"
    );
    is_string(
        $t5->text_html,
        q!DiCaprio neverdied in Titanic. last scene: going underwater. scene of Inception is him waking up on a beach.!
      . q!IT&#39;S A MOVIE INSIDE A MOVIE O.O!,
        "Fifth tweet as HTML matches"
    );
}

1;
