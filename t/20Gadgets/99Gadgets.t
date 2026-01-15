#!perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Gadgets';
}

isa_ok( new_TEventViewer( TRect->new(), 0 ),  TEventViewer() );

done_testing;
