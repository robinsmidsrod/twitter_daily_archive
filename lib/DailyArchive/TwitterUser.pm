#!/usr/bin/env perl

use strict;
use warnings;
package DailyArchive::TwitterUser;
use Moose;

use JSON::XS ();
use HTML::Entities ();
use URI ();

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
    return scalar JSON::XS::decode_json(
        $self->raw_json
    );
}

# The profile image url
has 'profile_image_url' => (
    is => 'ro',
    isa => 'URI',
    lazy_build => 1,
);

sub _build_profile_image_url {
    my ($self) = @_;
    return scalar URI->new(
        $self->json->{'profile_image_url'}
    );
}

# The twitter screen name (user name, nick, etc.)
has 'screen_name' => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_screen_name {
    my ($self) = @_;
    return $self->json->{'screen_name'};
}

# The twitter name (user full name)
has 'name' => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_name {
    my ($self) = @_;
    return $self->json->{'name'};
}

no Moose;
__PACKAGE__->meta->make_immutable();

1;
