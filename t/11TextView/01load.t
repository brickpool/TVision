#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Views::ScrollBar';
  use_ok 'TV::TextView::TextDevice';
}

isa_ok(
  TTextDevice->new(
    bounds      => TRect->new(), 
    aHScrollBar => TScrollBar->new( bounds => TRect->new() ), 
    aVScrollBar => TScrollBar->new( bounds => TRect->new() ),
  ), TTextDevice()
);
