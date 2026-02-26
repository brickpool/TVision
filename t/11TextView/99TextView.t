use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::TextView';
}

isa_ok( new_TTextDevice( TRect->new(), undef, undef ),  TTextDevice );
isa_ok( new_TTerminal( TRect->new(), undef, undef, 0 ), TTerminal );

done_testing();
