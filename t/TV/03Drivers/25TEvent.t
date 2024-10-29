 
=pod

=head1 DESCRIPTION

These test cases cover the creation of the TEvent object, the setting and 
retrieval of the fields and the behavior of the getKeyEvent method.

=cut

use strict;
use warnings;

use Test::More tests => 18;

# Mocking 'TV::Drivers::HardwareInfo' for testing purposes
BEGIN {
  package TV::Drivers::HardwareInfo;
  use Exporter 'import';
  our @EXPORT = qw( THardwareInfo );
  use TV::Drivers::Const qw(
    EV_KEY_DOWN
    KB_ALT_SHIFT
    KB_DEL
    KB_CTRL_SHIFT
    KB_INS
    KB_SHIFT
  );
  sub THardwareInfo (){__PACKAGE__ }
  my $hit;
  sub getKeyEvent {
    my ( $class, $ev ) = @_;
    $hit++;
    if ( $hit == 1 ) {
      $ev->{what}                     = EV_KEY_DOWN;
      $ev->{keyDown}{keyCode}         = ord( ' ' );
      $ev->{keyDown}{controlKeyState} = KB_ALT_SHIFT;
      return 1;
    }
    elsif ( $hit == 2 ) {
      $ev->{what}                     = EV_KEY_DOWN;
      $ev->{keyDown}{keyCode}         = KB_DEL;
      $ev->{keyDown}{controlKeyState} = KB_CTRL_SHIFT;
      return 1;
    }
    elsif ( $hit == 3 ) {
      $ev->{what}                     = EV_KEY_DOWN;
      $ev->{keyDown}{keyCode}         = KB_INS;
      $ev->{keyDown}{controlKeyState} = KB_SHIFT;
      return 1;
    }
    return 0;
  } #/ sub getKeyEvent
  $INC{"TV/Drivers/HardwareInfo.pm"} = 1;
}

BEGIN {
  use_ok 'TV::Objects::Point';
  use_ok 'TV::Drivers::Event';
  use_ok 'TV::Drivers::Const', qw(
    :evXXXX
    KB_ALT_SPACE
    KB_CTRL_DEL
    KB_SHIFT_DEL
    KB_CTRL_INS
    KB_SHIFT_INS
  );
  use_ok 'TV::Drivers::HardwareInfo';
}
use_ok 'CharScanType';
use_ok 'MouseEventType';
use_ok 'KeyDownEvent';
use_ok 'MessageEvent';

# Test object creation for mouse event
my $mouse_event = TEvent->new(
  what  => EV_MOUSE,
  mouse => {
    where           => [ 10, 20 ],
    eventFlags      => 1,
    controlKeyState => 2,
    buttons         => 3,
  }
);

isa_ok( $mouse_event, TEvent, 'Object is of class TEvent' );
is( $mouse_event->{what}, EV_MOUSE, 'Mouse event type is set correctly' );
is_deeply(
  $mouse_event->{mouse},
  my $me = MouseEventType->new(
    where => TPoint->new(
      x => 10,
      y => 20,
    ),
    eventFlags      => 1,
    controlKeyState => 2,
    buttons         => 3,
  ),
  'Mouse event data is set correctly'
);

# Test object creation for keyboard event
my $key_event = TEvent->new(
  what    => EV_KEYBOARD,
  keyDown => {
    charScan => CharScanType->new(
      charCode => 1,
      scanCode => 2,
    ),
    controlKeyState => 69,
  }
);

isa_ok( $key_event, TEvent, 'Object is of class TEvent' );
is( $key_event->{what}, EV_KEYBOARD, 'Keyboard event type is set correctly' );
is_deeply(
  $key_event->{keyDown},
  KeyDownEvent->new(
    keyCode         => 0x201,
    controlKeyState => 69
  ),
  'Keyboard event data is set correctly'
);

# Test object creation for message event
my $message_event = TEvent->new(
  what    => EV_MESSAGE,
  message => {
    command  => 1,
    infoLong => 0x12345678,
  }
);

isa_ok( $message_event, TEvent, 'Object is of class TEvent' );
is( $message_event->{what}, EV_MESSAGE, 'Message event type is set correctly' );
is_deeply(
  $message_event->{message},
  MessageEvent->new(
    command  => 1,
    infoLong => 0x12345678,
  ),
  'Message event data is set correctly'
);

# Test getKeyEvent method
subtest 'getKeyEvent method' => sub {
  plan tests => 5;
  my $key_event_test = TEvent->new( what => EV_KEYBOARD );
  is( ref($key_event_test->{keyDown}), 'KeyDownEvent',
    'Keyboard event data is set correctly' );

  $key_event_test->getKeyEvent();
  is( $key_event_test->{keyDown}{keyCode}, KB_ALT_SPACE,
    'getKeyEvent handles Alt-Space correctly' );

  $key_event_test->getKeyEvent();
  is( $key_event_test->{keyDown}{keyCode}, KB_CTRL_DEL,
    'getKeyEvent handles Ctrl-Del correctly' );

  $key_event_test->getKeyEvent();
  is( $key_event_test->{keyDown}{keyCode}, KB_SHIFT_INS,
    'getKeyEvent handles Shift-Ins correctly' );

  $key_event_test->getKeyEvent();
  is( $key_event_test->{what}, EV_NOTHING,
    'getKeyEvent handles no event correctly' );
};

done_testing;
