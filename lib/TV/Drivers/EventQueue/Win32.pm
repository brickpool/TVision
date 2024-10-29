package TV::Drivers::EventQueue::Win32;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TEventQueue
);

use TV::Drivers::Const qw( 
  :evXXXX 
  :meXXXX
);
use TV::Drivers::Event;
use TV::Drivers::HardwareInfo;
use TV::Drivers::Mouse;
use TV::Drivers::Screen;

sub TEventQueue() { __PACKAGE__ }

# predeclare global variable names
our $downTicks = 0;

our $mouseEvents  = !!0;
our $mouseReverse = !!0;
our $doubleDelay  = 8;
our $repeatDelay  = 8;
our $autoTicks    = 0;
our $autoDelay    = 0;

our $mouse     = TMouse;
our $lastMouse = MouseEventType->new();
our $curMouse  = MouseEventType->new();
our $downMouse = MouseEventType->new();
{
  no warnings 'once';
  *TEventQueue::downTicks = \$downTicks;

  *TEventQueue::mouseEvents  = \$mouseEvents;
  *TEventQueue::mouseReverse = \$mouseReverse;
  *TEventQueue::doubleDelay  = \$doubleDelay;
  *TEventQueue::repeatDelay  = \$repeatDelay;
  *TEventQueue::autoTicks    = \$autoTicks;
  *TEventQueue::autoDelay    = \$autoDelay;

  *TEventQueue::mouse     = \$mouse;
  *TEventQueue::lastMouse = \$lastMouse;
  *TEventQueue::curMouse  = \$curMouse;
  *TEventQueue::downMouse = \$downMouse;
}

INIT: {
  TEventQueue->resume();
}

END {
  TEventQueue->suspend();
}

sub resume {    # void ($class)
  if ( !$mouse->present() ) {
    $mouse->resume();
  }
  if ( !$mouse->present() ) {
    return;
  }

  $mouse->getEvent( $curMouse );
  $lastMouse = $curMouse;

  THardwareInfo->clearPendingEvent();

  $mouseEvents = !!1;
  TMouse->setRange( $TScreen::screenWidth - 1, $TScreen::screenHeight - 1 );
  return;
} #/ sub resume

sub suspend {    # void ($class)
  $mouse->suspend();
  return;
}

my $ticks = 0;

my $getMouseState = sub {    # $bool ($class, $ev)
  my ( $class, $ev ) = @_;
  $ev->{what} = EV_NOTHING;

  return !!0 unless THardwareInfo->getMouseEvent( $curMouse );

  if ( $mouseReverse && $curMouse->{buttons} && $curMouse->{buttons} != 3 ) {
    $curMouse->{buttons} ^= 3;
  }

  # Temporarily save tick count when event was read.
  $ticks = THardwareInfo->getTickCount();
  $ev->{mouse} = $curMouse->clone();
  return !!1;
}; #/ $getMouseState = sub

sub getMouseEvent {    # void ($class, $ev)
  my ( $class, $ev ) = @_;
  if ( $mouseEvents ) {
    if ( !$class->$getMouseState( $ev ) ) {
      return;
    }

    $ev->{mouse}{eventFlags} = 0;

    if ( !$ev->{mouse}{buttons} && $lastMouse->{buttons} ) {
      $ev->{what} = EV_MOUSE_UP;
      $lastMouse = $ev->{mouse}->clone();
      return;
    }

    if ( $ev->{mouse}{buttons} && !$lastMouse->{buttons} ) {
      if ( $ev->{mouse}{buttons} == $downMouse->{buttons}
        && $ev->{mouse}{where} == $downMouse->{where}
        && $ticks - $downTicks <= $doubleDelay
        && !( $downMouse->{eventFlags} & ME_DOUBLE_CLICK ) )
      {
        $ev->{mouse}{eventFlags} |= ME_DOUBLE_CLICK;
      }

      $downMouse  = $ev->{mouse};
      $autoTicks  = $ticks;
      $downTicks  = $ticks;
      $ticks      = 0;
      $autoDelay  = $repeatDelay;
      $ev->{what} = EV_MOUSE_DOWN;
      $lastMouse = $ev->{mouse}->clone();
      return;
    } #/ if ( $ev->{mouse}{buttons...})

    $ev->{mouse}{buttons} = $lastMouse->{buttons};

    if ( $ev->{mouse}{where} != $lastMouse->{where} ) {
      $ev->{what} = EV_MOUSE_MOVE;
      $ev->{mouse}{eventFlags} |= ME_MOUSE_MOVED;
      $lastMouse = $ev->{mouse}->clone();
      return;
    }

    if ( $ev->{mouse}{buttons} && $ticks - $autoTicks > $autoDelay ) {
      $autoTicks  = $ticks;
      $ticks      = 0;
      $autoDelay  = 1;
      $ev->{what} = EV_MOUSE_AUTO;
      $lastMouse = $ev->{mouse}->clone();
      return;
    }
  } #/ if ( $mouseEvents )

  $ev->{what} = EV_NOTHING;
} #/ sub getMouseEvent

1
