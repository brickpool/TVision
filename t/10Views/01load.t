#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Views::Window';
}

isa_ok(
  TWindow->new( bounds => TRect->new(), title => 'title', number => 1 ),
  TWindow
);
