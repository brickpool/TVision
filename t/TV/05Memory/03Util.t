use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
  use_ok 'TV::Memory::Util', qw( lowMemory );
}

is( lowMemory(), !!0, 'lowMemory returns correct value' );

done_testing;
