#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::NoWarnings;

use LWP::UserAgent::ExponentialBackoff;

$^W = 1;    # Set global warnings.
my $agent = LWP::UserAgent::ExponentialBackoff->new();
