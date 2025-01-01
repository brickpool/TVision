package TV::Drivers::EventQueue;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TEventQueue
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';

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

INIT: {
  TEventQueue->resume();
}

END {
  TEventQueue->suspend();
}

sub resume {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
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
  eval {
    TMouse->setRange( 
      $TV::Drivers::Screen::screenWidth - 1, 
      $TV::Drivers::Screen::screenHeight - 1 
    )
  };
  return;
} #/ sub resume

sub suspend {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  $mouse->suspend();
  return;
}

my $ticks = 0;

my $getMouseState = sub {    # $bool ($class, $ev)
  my ( $class, $ev ) = @_;
  assert ( $class and !ref $class );
  assert ( ref $ev );
  $ev->{what} = evNothing;

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
  assert ( $class and !ref $class );
  assert ( ref $ev );
  if ( $mouseEvents ) {
    if ( !$class->$getMouseState( $ev ) ) {
      return;
    }

    $ev->{mouse}{eventFlags} = 0;

    if ( !$ev->{mouse}{buttons} && $lastMouse->{buttons} ) {
      $ev->{what} = evMouseUp;
      $lastMouse = $ev->{mouse}->clone();
      return;
    }

    if ( $ev->{mouse}{buttons} && !$lastMouse->{buttons} ) {
      if ( $ev->{mouse}{buttons} == $downMouse->{buttons}
        && $ev->{mouse}{where} == $downMouse->{where}
        && $ticks - $downTicks <= $doubleDelay
        && !( $downMouse->{eventFlags} & meDoubleClick ) )
      {
        $ev->{mouse}{eventFlags} |= meDoubleClick;
      }

      $downMouse  = $ev->{mouse};
      $autoTicks  = $ticks;
      $downTicks  = $ticks;
      $ticks      = 0;
      $autoDelay  = $repeatDelay;
      $ev->{what} = evMouseDown;
      $lastMouse = $ev->{mouse}->clone();
      return;
    } #/ if ( $ev->{mouse}{buttons...})

    $ev->{mouse}{buttons} = $lastMouse->{buttons};

    if ( $ev->{mouse}{where} != $lastMouse->{where} ) {
      $ev->{what} = evMouseMove;
      $ev->{mouse}{eventFlags} |= meMouseMoved;
      $lastMouse = $ev->{mouse}->clone();
      return;
    }

    if ( $ev->{mouse}{buttons} && $ticks - $autoTicks > $autoDelay ) {
      $autoTicks  = $ticks;
      $ticks      = 0;
      $autoDelay  = 1;
      $ev->{what} = evMouseAuto;
      $lastMouse = $ev->{mouse}->clone();
      return;
    }
  } #/ if ( $mouseEvents )

  $ev->{what} = evNothing;
} #/ sub getMouseEvent

1
