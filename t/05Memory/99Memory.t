#!perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
  use_ok 'TV::Memory';
}

is( lowMemory(), !!0, 'lowMemory returns correct value' );

done_testing;
