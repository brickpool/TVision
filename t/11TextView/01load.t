#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Views::ScrollBar';
  use_ok 'TV::TextView::TextDevice';
  use_ok 'TV::TextView::Terminal';
}

isa_ok(
  TTextDevice->new(
    bounds      => TRect->new(), 
    hScrollBar => TScrollBar->new( bounds => TRect->new() ), 
    vScrollBar => TScrollBar->new( bounds => TRect->new() ),
  ), TTextDevice()
);

isa_ok(
  TTerminal->new(
    bounds      => TRect->new(), 
    hScrollBar => TScrollBar->new( bounds => TRect->new() ), 
    vScrollBar => TScrollBar->new( bounds => TRect->new() ),
    bufSize    => 0,
  ), TTerminal()
);
