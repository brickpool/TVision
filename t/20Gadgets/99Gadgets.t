#!perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Gadgets';
}

isa_ok( new_TEventViewer( TRect->new(), 0 ), TEventViewer() );
isa_ok( new_THeapView( TRect->new() ), THeapView() );
isa_ok( new_TClockView( TRect->new() ), TClockView() );

done_testing;
