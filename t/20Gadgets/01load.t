#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Gadgets::Const';
  use_ok 'TV::Gadgets::PrintConstants';
  use_ok 'TV::Gadgets::EventViewer';
}

isa_ok(
  TEventViewer->new( bounds => TRect->new(), aBufSize => 0), TEventViewer()
);
