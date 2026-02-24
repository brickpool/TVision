#!perl

use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Gadgets';
}

isa_ok( new_TEventViewer( TRect->new(), 0 ), TEventViewer() );
isa_ok( new_THeapView( TRect->new() ), THeapView() );

done_testing;
