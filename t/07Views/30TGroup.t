use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Views::Group';
}

isa_ok( TGroup->new( bounds => TRect->new() ), TGroup );

done_testing();
