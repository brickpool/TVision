#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Drivers::Const', qw( eventQSize );
  use_ok 'TV::Drivers::Util';
  use_ok 'TV::Drivers::HardwareInfo';
  use_ok 'TV::Drivers::Display';
  use_ok 'TV::Drivers::Screen';
  use_ok 'TV::Drivers::SystemError';
  use_ok 'TV::Drivers::Event';
  use_ok 'TV::Drivers::HWMouse';
  use_ok 'TV::Drivers::Mouse';
  use_ok 'TV::Drivers::EventQueue';
}

is( eventQSize, 16, 'eventQSize is 16' );
ok( THardwareInfo->getPlatform(),   'THardwareInfo is initiated' );
ok( TDisplay->getCrtMode(),         'TDisplay is initiated' );
ok( TScreen->getCrtMode(),          'TScreen is initiated' );
ok( TSystemError->can( 'suspend' ), 'TSystemError can suspend' );
ok( TEventQueue->can( 'suspend' ),  'TEventQueue can suspend' );

use_ok 'MouseEventType';
use_ok 'CharScanType';
use_ok 'KeyDownEvent';
use_ok 'MessageEvent';

isa_ok( CharScanType->new(),   'CharScanType' );
isa_ok( KeyDownEvent->new(),   'KeyDownEvent' );
isa_ok( MessageEvent->new(),   'MessageEvent' );
isa_ok( MouseEventType->new(), 'MouseEventType' );
isa_ok( TEvent->new(),         TEvent );

SKIP: {
  skip 'No mouse available', 2 unless THardwareInfo->getButtonCount();
  ok( THWMouse->present(), 'THWMouse is present' );
  ok( TMouse->present(),   'TMouse is present' );
}

