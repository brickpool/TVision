#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Views::Const';
  use_ok 'TV::Views::CommandSet';
  use_ok 'TV::Views::DrawBuffer';
  use_ok 'TV::Views::Palette';
  use_ok 'TV::Views::View::Cursor';
  use_ok 'TV::Views::View::Exposed';
  use_ok 'TV::Views::View::Write';
  use_ok 'TV::Views::View';
  use_ok 'TV::Views::Group';
  use_ok 'TV::Views::Frame::Line';
  use_ok 'TV::Views::Frame';
  use_ok 'TV::Views::ScrollBar';
  use_ok 'TV::Views::Scroller';
  use_ok 'TV::Views::Window';
  use_ok 'TV::Views::WindowInit';
}

isa_ok( TCommandSet->new(), TCommandSet );
isa_ok( TPalette->new(), TPalette );
isa_ok( TView->new( bounds => TRect->new() ), TView );
isa_ok( TGroup->new( bounds => TRect->new() ), TGroup );
isa_ok( TFrame->new( bounds => TRect->new() ), TFrame );
isa_ok( TScrollBar->new( bounds => TRect->new() ), TScrollBar );
isa_ok(
  TScroller->new(
    bounds      => TRect->new(), 
    aHScrollBar => TScrollBar->new( bounds => TRect->new() ), 
    aVScrollBar => TScrollBar->new( bounds => TRect->new() ),
  ), TScroller
);
isa_ok( TWindowInit->new( cFrame => sub { } ), TWindowInit );
