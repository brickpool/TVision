#!perl

use strict;
use warnings;

use Test::More tests => 9;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::App';
}

is( apColor, 0, 'apColor is 0' );
isa_ok( new_TBackground( TRect->new(), '#' ), TBackground );
isa_ok( new_TDeskInit( sub { } ),             TDeskInit );
isa_ok( new_TDeskTop( TRect->new() ),         TDeskTop );
isa_ok( new_TProgInit( ( sub { } ) x 3 ),     TProgInit );
ok( TProgram->can( 'new_TProgram' ),         'new_TProgram() exists' );
ok( TApplication->can( 'new_TApplication' ), 'new_TApplication() exists' );

done_testing;
