#!/usr/bin/env perl

use strict;
use warnings;
package DailyArchive::Tweet;
use Moose;

use HTML::Entities ();
use feature 'switch';

# The raw JSON text in binary UTF8
has 'raw_json' => (
    is => 'ro',
    isa => 'Str',
    default => '{}',
);

# The decoded JSON data structure
has 'json' => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);

sub _build_json {
    my ($self) = @_;
    return JSON::XS::decode_json($self->raw_json);
}

# The message from the tweet in plain text format (includes HTML entities)
has '_text_raw' => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build__text_raw {
    my ($self) = @_;
    return $self->is_retweet
         ? $self->json->{'retweeted_status'}->{'text'}
         : $self->json->{'text'};
}

# The message from the tweet in plain text format (no HTML entities)
has 'text' => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_text {
    my ($self) = @_;
    return HTML::Entities::decode( $self->_text_raw );
}

# Returns true if the tweet is a verbatim retweet
has 'is_retweet' => (
    is => 'ro',
    isa => 'Bool',
    lazy_build => 1,
);

sub _build_is_retweet {
    my ($self) = @_;
    return $self->json->{'retweeted_status'} ? 1 : 0;
}

# Twitter entities mentioned in message (hash tags, user mentions and urls)
has 'entities' => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);

sub _build_entities {
    my ($self) = @_;
    return $self->is_retweet
         ? ( $self->json->{'retweeted_status'}->{'entities'} || {} )
         : ( $self->json->{'entities'} || {} );
}

# The hash tags mentioned in the text
has 'hashtags' => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
);

sub _build_hashtags {
    my ($self) = @_;
    return $self->entities->{'hashtags'} || [];
}

# The users mentioned in the text
has 'user_mentions' => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
);

sub _build_user_mentions {
    my ($self) = @_;
    return $self->entities->{'user_mentions'} || [];
}

# The urls mentioned in the text
has 'urls' => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
);

sub _build_urls {
    my ($self) = @_;
    return $self->entities->{'urls'} || [];
}

# The message from the tweet in HTML format, ready to be injected on a web page
has 'text_html' => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_text_html {
    my ($self) = @_;
    return join("", @{ $self->text_parts_html_expanded } );
}

# The different entities of the message text, according to the entity indices
has '_entity_index_map' => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);

sub _build__entity_index_map {
    my ($self) = @_;
    my %indices;
    foreach my $hashtag ( @{ $self->hashtags } ) {
        $indices{ $hashtag->{'indices'}->[0] } = { type => 'hashtag', data => $hashtag };
        $indices{ $hashtag->{'indices'}->[1] } = { type => 'text' };
    }
    foreach my $user_mention ( @{ $self->user_mentions } ) {
        $indices{ $user_mention->{'indices'}->[0] } = { type => 'user_mention', data => $user_mention };
        $indices{ $user_mention->{'indices'}->[1] } = { type => 'text' };
    }
    foreach my $url ( @{ $self->urls } ) {
        $indices{ $url->{'indices'}->[0] } = { type => 'url', data => $url };
        $indices{ $url->{'indices'}->[1] } = { type => 'text' };
    }
    # Add normal text from start of message
    unless ( exists $indices{"0"} ) {
        $indices{"0"} = { type => 'text' };
    }
    return \%indices;
}

# The index positions of different entities in the text message
has '_text_indices' => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
    lazy_build => 1,
);

sub _build__text_indices {
    my ($self) = @_;
    my @indices = sort { $a <=> $b } keys %{ $self->_entity_index_map };
    return \@indices;
}

# The actual text of the different parts of the text, broken up by the entities
has 'text_parts' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    lazy_build => 1,
);

sub _build_text_parts {
    my ($self) = @_;
    my @parts;
    my $index_count = @{ $self->_text_indices };
    for( my $i = 0; $i < $index_count; $i++ ) {
        if ( exists $self->_text_indices->[$i+1] ) {
            my $cur_pos = $self->_text_indices->[$i];
            my $next_pos = $self->_text_indices->[$i+1];
            my $len = $next_pos - $cur_pos;
            push @parts, HTML::Entities::decode(
                substr $self->_text_raw, $cur_pos, $len
            );
        }
        else {
            push @parts, HTML::Entities::decode(
                substr $self->_text_raw, $self->_text_indices->[$i]
            ); # Last part
        }
    }
    return \@parts;
}

# All parts of the text message encoded for output to a web page
has 'text_parts_html' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    lazy_build => 1,
);

sub _build_text_parts_html {
    my ($self) = @_;
    return [
        map { HTML::Entities::encode($_) }
        @{ $self->text_parts }
    ];
}

# All parts of text message encoded for output to a web page
# and user_mentions, urls and hashtags expanded
has 'text_parts_html_expanded' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    lazy_build => 1,
);

sub _build_text_parts_html_expanded {
    my ($self) = @_;
    my @parts;
    my $index_count = @{ $self->_text_indices };
    for( my $i = 0; $i < $index_count; $i++ ) {
        my $text = $self->text_parts_html->[$i];
        my $index = $self->_text_indices->[$i];
        my $entity = $self->_entity_index_map->{$index};
        my $entity_data = $entity->{'data'};
        my $entity_type = $entity->{'type'};
        given($entity_type) {
            when('hashtag') {
                my $hashtag_encoded = HTML::Entities::encode( $entity_data->{'text'} );
                my $output = q!<a class="hashtag" href="http://twitter.com/search/%23!
                           . $hashtag_encoded
                           . q!" title="Search Twitter for !
                           . $text
                           . q!" target="_blank">!
                           . $text
                           . q!</a>!;
                push @parts, $output;
            }
            when('user_mention') {
                my $screen_name_encoded = HTML::Entities::encode( $entity_data->{'screen_name'} );
                my $name_encoded = HTML::Entities::encode( $entity_data->{'name'} );
                my $output = q!<a class="user_mention" href="http://twitter.com/!
                           . $screen_name_encoded
                           . q!/" title="Twitter homepage for !
                           . $name_encoded
                           . q!" target="_blank">!
                           . $text
                           . q!</a>!;
                push @parts, $output;
            }
            when('url') {
                my $is_expanded = exists $entity_data->{'display_url'} ? 1 : 0;
                my $display_url = $is_expanded
                                ? HTML::Entities::encode(
                                      $entity_data->{'display_url'}
                                  )
                                : "";
                my $output = q!<a class="url" href="!
                           . $text
                           . q!" !
                           . ( $is_expanded ? q!title="! . $display_url . q!" ! : "" )
                           . q!target="_blank">!
                           . $text
                           . q!</a>!;
                push @parts, $output;
            }
            default {
                push @parts, $text;
            }
        }
    };
    return \@parts;
}

no Moose;
__PACKAGE__->meta->make_immutable();

1;
