use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Gadgets::Const';
  use_ok 'TV::Gadgets::PrintConstants';
  use_ok 'TV::Gadgets::EventViewer';
  use_ok 'TV::Gadgets::HeapView';
  use_ok 'TV::Gadgets::ClockView';
}

isa_ok(
  TEventViewer->new( bounds => TRect->new(), bufSize => 0 ), TEventViewer()
);
isa_ok( THeapView->new( bounds => TRect->new() ), THeapView() );
isa_ok( TClockView->new( bounds => TRect->new() ), TClockView() );

done_testing();
