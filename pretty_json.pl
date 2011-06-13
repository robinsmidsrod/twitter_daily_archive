#!/usr/bin/env perl

use strict;
use warnings;

use File::Slurp;
use JSON::XS;

print JSON::XS->new->pretty->encode(
    JSON::XS->new->utf8->decode(
        read_file(shift)
    )
)
