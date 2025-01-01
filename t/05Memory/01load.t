#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Memory::Util', qw( lowMemory );
}
