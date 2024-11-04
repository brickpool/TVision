=pod

=head1 NAME

TV::Views::View - defines the class TView

=cut

package TV::Views::View;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT = qw(
  TView
);

use Data::Alias;
use Devel::StrictMode;
use Hash::Util::FieldHash qw( id );
use List::Util qw( min max );
use Scalar::Util qw( blessed );

use TV::Const qw(
  INT_MAX
  MAX_VIEW_WIDTH
);
use TV::Util qw( message );
use TV::Objects::Point;
use TV::Objects::Rect;
use TV::Drivers::Const qw(
  :evXXXX
  :kbXXXX
);
use TV::Drivers::DrawBuffer;
use TV::Drivers::Event;
use TV::Drivers::HardwareInfo;
use TV::Drivers::Screen;
use TV::Views::Const qw(
  :cmXXXX
  :dmXXXX
  :gfXXXX
  :hcXXXX
  :ofXXXX
  :phXXXX
  :sfXXXX
  :smXXXX
);
use TV::Views::CommandSet;
use TV::Views::Palette;

sub TView() { __PACKAGE__ }

our %REF = ();
our $shadowSize        = TPoint->new( x => 2, y => 1 );
our $shadowAttr        = 0x08;
our $showMarkers       = !!0;
our $errorAttr         = 0xcf;
our $commandSetChanged = !!0;
our $TheTopView;
{
  no warnings 'once';
  TView->{REF}                     = \%REF;
  alias TView->{shadowSize}        = $shadowSize;
  alias TView->{shadowAttr}        = $shadowAttr;
  alias TView->{showMarkers}       = $showMarkers;
  alias TView->{errorAttr}         = $errorAttr;
  alias TView->{commandSetChanged} = $commandSetChanged;
  alias TView->{TheTopView}        = $TheTopView;
}

my $initCommands = sub {
  my $temp = TCommandSet->new();
  for ( my $i = 0 ; $i < 256 ; $i++ ) {
    $temp->enableCmd( $i );
  }
  $temp->disableCmd( CM_ZOOM );
  $temp->disableCmd( CM_CLOSE );
  $temp->disableCmd( CM_RESIZE );
  $temp->disableCmd( CM_NEXT );
  $temp->disableCmd( CM_PREV );
  return $temp;
}; #/ $initCommands = sub

our $curCommandSet = $initCommands->();
{
  no warnings 'once';
  alias TView->{curCommandSet} = $curCommandSet;
}

sub new {    # $obj (%args)
  my ( $class, %args ) = @_;
  my $self = bless {
    owner     => undef,
    next      => undef,
    options   => 0,
    state     => SF_VISIBLE,
    growMode  => 0,
    dragMode  => DM_LIMIT_LO_Y,
    helpCtx   => HC_NO_CONTEXT,
    eventMask => EV_MOUSE_DOWN | EV_KEY_DOWN | EV_COMMAND,
    size      => TPoint->new(),
    origin    => TPoint->new(),
    cursor    => TPoint->new(), # $cursor->{x} = $cursor->{y} = 0;
  }, $class;
  $self->setBounds( $args{bounds} );
  $REF{ id $self } = $self;
  return $self;
} #/ sub new

sub DESTROY { # void ()
  my $id = id shift;
  delete $REF{$id};
  return;
}

sub sizeLimits {    # void ($min, $max)
  my ( $self, $min, $max ) = @_;
  $min->{x} = $min->{y} = 0;
  if ( !( $self->{growMode} & GF_FIXED ) && $self->owner() ) {
    $max->{x} = $self->owner()->{size}{x};
    $max->{y} = $self->owner()->{size}{y};
  }
  else {
    $max->{x} = $max->{y} = INT_MAX;
  }
  return;
} #/ sub sizeLimits

sub getBounds {    # $rect ()
  my $self = shift;
  return TRect->new(
    a => $self->{origin},
    b => $self->{origin} + $self->{size},
  );
}

sub getExtent {    # $rect ()
  my $self = shift;
  return TRect->new(
    ax => 0,
    ay => 0,
    bx => $self->{size}{x},
    by => $self->{size}{y},
  );
}

sub getClipRect {    # $rect ()
  my $self = shift;
  my $clip = $self->getBounds();
  if ( $self->owner() ) {
    $clip->intersect( $self->owner()->{clip} );
  }
  $clip->move( -$self->{origin}{x}, -$self->{origin}{y} );
  return $clip;
}

sub mouseInView {    # $bool ($mouse)
  my ( $self, $mouse ) = @_;
  $mouse = $self->makeLocal( $mouse->clone() );
  my $r = $self->getExtent();
  return $r->contains( $mouse );
}

sub containsMouse {    # $bool ($event)
  my ( $self, $event ) = @_;
  return ( $self->{state} & SF_VISIBLE )
    && $self->mouseInView( $event->{mouse}{where} );
}

# Define the range function
my $range = sub {    # $ ($val, $min, $max)
  my ( $val, $min, $max ) = @_;
  return ( $val < $min ) ? $min : ( ( $val > $max ) ? $max : $val );
};

sub locate {    # void ($bounds)
  my ( $self, $bounds ) = @_;
  my ( $min,  $max )    = ( TPoint->new(), TPoint->new() );
  $self->sizeLimits( $min, $max );
  $bounds->{b}{x} = $bounds->{a}{x} +
    $range->( $bounds->{b}{x} - $bounds->{a}{x}, $min->{x}, $max->{x} );
  $bounds->{b}{y} = $bounds->{a}{y} +
    $range->( $bounds->{b}{y} - $bounds->{a}{y}, $min->{y}, $max->{y} );
  my $r = $self->getBounds();
  if ( $bounds != $r ) {
    $self->changeBounds( $bounds );
    if ( $self->owner() && ( $self->{state} & SF_VISIBLE ) ) {
      if ( $self->{state} & SF_SHADOW ) {
        $r->Union( $bounds );
        $r->{b} += $shadowSize;
      }
      $self->drawUnderRect( $r, 0 );
    }
  } #/ if ( $bounds != $r )
  return;
} #/ sub locate

my $moveGrow = sub {
  my ( $self, $p, $s, $limits, $minSize, $maxSize, $mode ) = @_;

  $p = $p->clone();
  $s = $s->clone();

  $s->{x} = min( max( $s->{x}, $minSize->{x} ), $maxSize->{x} );
  $s->{y} = min( max( $s->{y}, $minSize->{y} ), $maxSize->{y} );
  $p->{x} = min(
    max( $p->{x}, $limits->{a}{x} - $s->{x} + 1 ),
    $limits->{b}{x} - 1
  );
  $p->{y} = min(
    max( $p->{y}, $limits->{a}{y} - $s->{y} + 1 ),
    $limits->{b}{y} - 1
  );

  if ( $mode & DM_LIMIT_LO_X ) {
    $p->{x} = max( $p->{x}, $limits->{a}{x} );
  }
  if ( $mode & DM_LIMIT_LO_Y ) {
    $p->{y} = max( $p->{y}, $limits->{a}{y} );
  }
  if ( $mode & DM_LIMIT_HI_X ) {
    $p->{x} = min( $p->{x}, $limits->{b}{x} - $s->{x} );
  }
  if ( $mode & DM_LIMIT_HI_Y ) {
    $p->{y} = min( $p->{y}, $limits->{b}{y} - $s->{y} );
  }

  my $r = TRect->new(
    ax => $p->{x},
    ay => $p->{y},
    bx => $p->{x} + $s->{x},
    by => $p->{y} + $s->{y},
  );
  $self->locate( $r );
  return;
}; #/ $moveGrow = sub

my $change = sub {    # void ($mode, $delta, $p, $s, $ctrlState)
  my ( $self, $mode, $delta, $p, $s, $ctrlState ) = @_;
  if ( ( $mode & DM_DRAG_MOVE ) && !( $ctrlState & !KB_SHIFT ) ) {
    $p += $delta;
  }
  elsif ( ( $mode & DM_DRAG_GROW ) && ( $ctrlState & KB_SHIFT ) ) {
    $s += $delta;
  }
  return;
}; #/ sub

my ( $goLeft, $goRight, $goUp, $goDown, $goCtrlLeft, $goCtrlRight );

sub dragView {    # void ($event, $mode, $limits, $minSize, $maxSize)
  my ( $self, $event, $mode, $limits, $minSize, $maxSize ) = @_;
  my $saveBounds;

  my ( $p, $s );
  $self->setState( SF_DRAGGING, !!1 );

  if ( $event->{what} == EV_MOUSE_DOWN ) {
    if ( $mode & DM_DRAG_MOVE ) {
      $p = $self->{origin} - $event->{mouse}{where};
      do {
        $event->{mouse}{where} += $p;
        $self->$moveGrow(
          $event->{mouse}{where}, $self->{size}, $limits, $minSize,
          $maxSize, $mode
        );
      } while ( $self->mouseEvent( $event, EV_MOUSE_MOVE ) );
    } #/ if ( $mode & DM_DRAG_MOVE)
    else {
      $p = $self->{size} - $event->{mouse}{where};
      do {
        $event->{mouse}{where} += $p;
        $self->$moveGrow(
          $self->{origin}, $event->{mouse}{where}, $limits, $minSize,
          $maxSize,        $mode
        );
      } while ( $self->mouseEvent( $event, EV_MOUSE_MOVE ) );
    } #/ else [ if ( $mode & DM_DRAG_MOVE)]
  } #/ if ( $event->{what} ==...)
  else {
    $goLeft      ||= TPoint->new( x => -1, y =>  0 );
    $goRight     ||= TPoint->new( x =>  1, y =>  0 );
    $goUp        ||= TPoint->new( x =>  0, y => -1 );
    $goDown      ||= TPoint->new( x =>  0, y =>  1 );
    $goCtrlLeft  ||= TPoint->new( x => -8, y =>  0 );
    $goCtrlRight ||= TPoint->new( x =>  8, y =>  0 );

    $saveBounds = $self->getBounds();
    do {
      $p = $self->{origin}->clone();
      $s = $self->{size}->clone();
      $self->keyEvent( $event );
      SWITCH: for ( $event->{keyDown}{keyCode} & 0xff00 ) {
        $_ == KB_LEFT and do {
          $self->$change( $mode, $goLeft, $p, $s, 
            $event->{keyDown}{controlKeyState} );
          last;
        };
        $_ == KB_RIGHT and do {
          $self->$change( $mode, $goRight, $p, $s, 
            $event->{keyDown}{controlKeyState} );
          last;
        };
        $_ == KB_UP and do {
          $self->$change( $mode, $goUp, $p, $s, 
            $event->{keyDown}{controlKeyState} );
          last;
        };
        $_ == KB_DOWN and do {
          $self->$change( $mode, $goDown, $p, $s, 
            $event->{keyDown}{controlKeyState} );
          last;
        };
        $_ == KB_CTRL_LEFT and do {
          $self->$change(
            $mode, $goCtrlLeft, $p, $s,
            $event->{keyDown}{controlKeyState}
          );
          last;
        };
        $_ == KB_CTRL_RIGHT and do {
          $self->$change(
            $mode, $goCtrlRight, $p, $s,
            $event->{keyDown}{controlKeyState}
          );
          last;
        };
        $_ == KB_HOME and do {
          $p->{x} = $limits->{a}{x};
          last;
        };
        $_ == KB_END and do {
          $p->{x} = $limits->{b}{x} - $s->{x};
          last;
        };
        $_ == KB_PG_UP and do {
          $p->{y} = $limits->{a}{y};
          last;
        };
        $_ == KB_PG_DN and do {
          $p->{y} = $limits->{b}{y} - $s->{y};
          last;
        };
      }
      $self->$moveGrow( $p, $s, $limits, $minSize, $maxSize, $mode );
    } while ( $event->{keyDown}{keyCode} != KB_ESC
           && $event->{keyDown}{keyCode} != KB_ENTER 
          );
    if ( $event->{keyDown}{keyCode} == KB_ESC ) {
      $self->locate( $saveBounds );
    }
  } #/ else [ if ( $event->{what} ==...)]
  $self->setState( SF_DRAGGING, !!0 );
} #/ sub dragView

my $grow;

sub calcBounds {    # void ($bounds, $delta);
  my ( $self, undef, $delta ) = @_;
  alias my $bounds = $_[1];

  my ( $s, $d );

  $grow ||= sub {
    if ( $self->{growMode} & GF_GROW_REL ) {
      $_[0] = ( $_[0] * $s + ( ( $s - $d ) >> 1 ) ) / ( $s - $d );
    }
    else {
      $_[0] += $d;
    }
  };

  $bounds = $self->getBounds();

  $s = $self->owner()->{size}{x};
  $d = $delta->{x};

  if ( $self->{growMode} & GF_GROW_LO_X ) {
    $grow->( $bounds->{a}{x} );
  }

  if ( $self->{growMode} & GF_GROW_HI_X ) {
    $grow->( $bounds->{b}{x} );
  }

  $s = $self->owner()->{size}{y};
  $d = $delta->{y};

  if ( $self->{growMode} & GF_GROW_LO_Y ) {
    $grow->( $bounds->{a}{y} );
  }

  if ( $self->{growMode} & GF_GROW_HI_Y ) {
    $grow->( $bounds->{b}{y} );
  }

  my ( $minLim, $maxLim ) = ( TPoint->new(), TPoint->new() );
  $self->sizeLimits( $minLim, $maxLim );
  $bounds->{b}{x} = $bounds->{a}{x} +
    $range->( $bounds->{b}{x} - $bounds->{a}{x}, $minLim->{x}, $maxLim->{x} );
  $bounds->{b}{y} = $bounds->{a}{y} +
    $range->( $bounds->{b}{y} - $bounds->{a}{y}, $minLim->{y}, $maxLim->{y} );
  return;
} #/ sub calcBounds

sub changeBounds {    # void ($bounds)
  my ( $self, $bounds ) = @_;
  $self->setBounds( $bounds );
  $self->drawView();
  return;
}

sub growTo {    # void ($x, $y)
  my ( $self, $x, $y ) = @_;
  my $r = TRect->new(
    ax => $self->{origin}{x},
    ay => $self->{origin}{y},
    bx => $self->{origin}{x} + $x,
    by => $self->{origin}{y} + $y,
  );
  $self->locate( $r );
  return;
} #/ sub growTo

sub moveTo {    # void ($x, $y)
  my ( $self, $x, $y ) = @_;
  my $r = TRect->new(
    ax => $x,
    ay => $y,
    bx => $x + $self->{size}{x},
    by => $y + $self->{size}{y},
  );
  $self->locate( $r );
  return;
} #/ sub moveTo

sub setBounds {    # void ($bounds)
  my ( $self, $bounds ) = @_;
  $self->{origin} = $bounds->{a}->clone;
  $self->{size}   = $bounds->{b} - $bounds->{a};
  return;
}

sub getHelpCtx {  # $int ()
  my $self = shift;
  if ( $self->{state} & SF_DRAGGING ) {
    return HC_DRAGGING;
  }
  return $self->{helpCtx};
}

sub valid {    # $bool ($command)
  return !!1;
}

sub hide {    # void ()
  my $self = shift;
  if ( $self->{state} & SF_VISIBLE ) {
    $self->setState( SF_VISIBLE, !!0 );
  }
  return;
}

sub show {    # void ()
  my $self = shift;
  if ( ( $self->{state} & SF_VISIBLE ) == 0 ) {
    $self->setState( SF_VISIBLE, !!1 );
  }
  return;
}

sub draw {    # void ()
  my $self = shift;
  my $b    = TDrawBuffer->new();

  $b->moveChar( 0, ' ', $self->getColor( 1 ), $self->{size}{x} );
  $self->writeLine( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  return;
}

sub drawView {    # void ()
  my $self = shift;
  if ( $self->exposed() ) {
    $self->draw();
    $self->drawCursor();
  }
  return;
}

# The L</exposed> method is a port of the assembler code of I<tvexposd.asm>.
#
# The following code base was originally written by Jörn Sierwald in C++ and 
# ported now to Perl.

my $staticVars2 = {
  target  => undef,
  offset  => 0,
  y       => 0,
};
my ( $exposedRec1, $exposedRec2 );

$exposedRec1 = sub {    # $bool ($self, $x1, $x2, $p)
  my ( $self, $x1, $x2, $p ) = @_;
  while ( 1 ) {
    $p = $p->{next};
    return $self->$exposedRec2( $x1, $x2, $p->owner() )    # run completed
      if $p == $staticVars2->{target};

    next                                                   # no overlapping
      if !( $p->{state} & SF_VISIBLE )
      && $staticVars2->{y} < $p->{origin}{y};

    if ( $staticVars2->{y} < $p->{origin}{y} + $p->{size}{y} ) {

      # overlapping possible
      if ( $x1 < $p->{origin}{x} ) {    # starts left of view
        next                           # left complete
          if $x2 <= $p->{origin}{x};
        if ( $x2 > $p->{origin}{x} + $p->{size}{x} ) {
          return !!1
            if $self->$exposedRec1( $x1, $p->{origin}{x}, $p );
          $x1 = $p->{origin}{x} + $p->{size}{x};
        }
        else {
          $x2 = $p->{origin}{x};
        }
      } #/ if ( $x1 < $p->{origin...})
      else {
        $x1 = max( $x1, $p->{origin}{x} + $p->{size}{x} );
        return !!0    # completely hidden
          if $x1 >= $x2;
      }
    } #/ if ( $staticVars2->{y}...)
  } #/ while ( 1 )
}; #/ $exposedRec1 = sub

$exposedRec2 = sub {    # $bool ($self, $x1, $x2, $p)
  my ( $self, $x1, $x2, $p ) = @_;
  return !!0
    unless $p->{state} & SF_VISIBLE;

  my $owner = $p->owner();
  return !!1
    if !$owner || $owner->{buffer};

  my $savedStatics = {%$staticVars2};

  $staticVars2->{y} += $p->{origin}{y};
  $x1               += $p->{origin}{x};
  $x2               += $p->{origin}{x};
  $staticVars2->{target} = $p;

  my $exposed = !!0;
  if ( $staticVars2->{y} >= $owner->{clip}{a}{y}
    && $staticVars2->{y} <  $owner->{clip}{b}{y} 
  ) {
    $x1 = max( $x1, $owner->{clip}{a}{x} );
    $x2 = min( $x2, $owner->{clip}{b}{x} );
    if ( $x1 < $x2 ) {
      $exposed = $self->$exposedRec1( $x1, $x2, $owner->{last} );
    }
  }

  $staticVars2 = {%$savedStatics};
  return $exposed;
}; #/ $exposedRec2 = sub

sub exposed {    # $bool ()
  my $self = shift;
  return !!0
    if !( $self->{state} & SF_EXPOSED )
    || $self->{size}{x} <= 0
    || $self->{size}{y} <= 0;
  for ( my $y = 0 ; $y < $self->{size}{y} ; $y++ ) {
    $staticVars2->{y} = $y;
    return !!1
      if $self->$exposedRec2( 0, $self->{size}{x}, $self );
  }
  return !!0;
} #/ sub exposed

sub focus {    # $bool ()
  my $self   = shift;
  my $result = !!1;

  if ( !( $self->{state} & ( SF_SELECTED | SF_MODAL ) ) ) {
    if ( $self->owner() ) {
      $result = $self->owner()->focus();
      if ( $result ) {
        if ( !$self->owner()->{current}
          || !( $self->owner()->{current}{options} & OF_VALIDATE )
          || $self->owner()->{current}->valid( CM_RELEASED_FOCUS ) )
        {
          $self->select();
        }
        else {
          return !!0;
        }
      } #/ if ( $result )
    } #/ if ( $self->owner() )
  } #/ if ( !( $self->{state}...))
  return $result;
} #/ sub focus

sub hideCursor {    # void ()
  my $self = shift;
  $self->setState( SF_CURSOR_VIS, !!0 );
  return;
}

sub drawHide {    # void ($lastView)
  my ( $self, $lastView ) = @_;
  $self->drawCursor();
  $self->drawUnderView( $self->{state} & SF_SHADOW, $lastView );
  return;
}

sub drawShow {    # void ($lastView)
  my ( $self, $lastView ) = @_;
  $self->drawView();
  if ( $self->{state} & SF_SHADOW ) {
    $self->drawUnderView( !!1, $lastView );
  }
  return;
}

sub drawUnderRect {    # void ($r, $lastView)
  my ( $self, $r, $lastView ) = @_;
  $self->owner()->{clip}->intersect( $r );
  $self->owner()->drawSubViews( $self->nextView(), $lastView );
  $self->owner()->{clip} = $self->owner()->getExtent();
  return;
}

sub drawUnderView {    # void ($doShadow, $lastView)
  my ( $self, $doShadow, $lastView ) = @_;
  my $r = $self->getBounds();
  if ( $doShadow ) {
    $r->{b} += $shadowSize;
  }
  $self->drawUnderRect( $r, $lastView );
  return;
}

sub dataSize {    # $size ()
  return 0;
}

sub getData {    # void ($rec)
  return;
}

sub setData {    # void ($rec)
  return;
}

sub awaken {    # void ()
  return;
}

sub blockCursor {    # void ()
  my $self = shift;
  $self->setState( SF_CURSOR_INS, !!1 );
  return;
}

sub normalCursor {    # void ()
  my $self = shift;
  $self->setState( SF_CURSOR_INS, !!0 );
  return;
}

# The L</resetCursor> method is a port of the assembler code of I<tvcursor.asm>.
#
# The following code base was originally written by Jörn Sierwald in C++ and 
# ported now to Perl.

sub resetCursor {    # void ()
  my ( $self ) = @_;

  if ( ( $self->{state} & ( SF_VISIBLE | SF_CURSOR_VIS | SF_FOCUSED ) ) ==
    ( SF_VISIBLE | SF_CURSOR_VIS | SF_FOCUSED ) 
  ) {
    my ( $p2, $g );
    my $p   = $self;
    my $cur = $self->{cursor};

    while ( 1 ) {
      last
        unless $cur->{x} >= 0
        && $cur->{x} < $p->{size}->{x}
        && $cur->{y} >= 0
        && $cur->{y} < $p->{size}->{y};
      $cur->{x} += $p->{origin}->{x};
      $cur->{y} += $p->{origin}->{y};
      $p2 = $p;
      $g  = $p->owner();

      if ( !$g ) {
        # Cursor is visible, so set it's position
        THardwareInfo->setCaretPosition( $cur->{x}, $cur->{y} );
        # Determine cursor size
        my $size = TScreen->{cursorLines};
        $size = 100 
          if $self->{state} & SF_CURSOR_INS;
        THardwareInfo->setCursorType( $size );
        return;
      }

      last 
        unless $g->{state} & SF_VISIBLE;
      $p = $g->{last};

      while ( 1 ) {
        $p = $p->{next};
        if ( $p eq $p2 ) {    # all checked
          $p = $p->owner();
          next;
        }
        last                  # Cursor is hidden
          if ( $p->{state} & SF_VISIBLE )
          && $cur->{x} >= $p->{origin}->{x}
          && $cur->{x} < $p->{size}->{x} + $p->{origin}->{x}
          && $cur->{y} >= $p->{origin}->{y}
          && $cur->{y} < $p->{size}->{y} + $p->{origin}->{y};
      } #/ while ( 1 )
    } #/ while ( 1 )
  } #/ if ( ( $self->{state} ...))

  # Cursor is not visible if we get here
  THardwareInfo->setCursorType( 0 );
  return;
} #/ sub resetCursor

sub setCursor {    # void ($x, $y)
  my ( $self, $x, $y ) = @_;
  $self->{cursor}{x} = $x;
  $self->{cursor}{y} = $y;
  $self->drawCursor();
  return;
}

sub showCursor {    # void ()
  my $self = shift;
  $self->setState( SF_CURSOR_VIS, !!1 );
  return;
}

sub drawCursor {    # void ()
  my $self = shift;
  if ( $self->{state} & SF_FOCUSED ) {
    $self->resetCursor();
  }
  return;
}

sub clearEvent {    # void ($event)
  my ( $self, $event ) = @_;
  $event->{what}    = EV_NOTHING;
  $event->{message} = MessageEvent->new( infoPtr => $self );
  return;
}

sub eventAvail {    # $bool ()
  my $self  = shift;
  my $event = TEvent->new();
  $self->getEvent( $event );
  if ( $event->{what} != EV_NOTHING ) {
    $self->putEvent( $event );
  }
  return $event->{what} != EV_NOTHING;
}

sub getEvent {    # void ($event)
  my ( $self, $event ) = @_;
  if ( $self->owner() ) {
    $self->owner()->getEvent( $event );
  }
  return;
}

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  if ( $event->{what} == EV_MOUSE_DOWN ) {
    if ( !( $self->{state} & ( SF_SELECTED | SF_DISABLED ) )
      && ( $self->{options} & OF_SELECTABLE )
    ) {
      if ( !$self->focus() || !( $self->{options} & OF_FIRST_CLICK ) ) {
        $self->clearEvent( $event );
      }
    }
  }
  return;
} #/ sub handleEvent

sub putEvent {    # void ($event)
  my ( $self, $event ) = @_;
  $self->owner()->putEvent( $event )
    if $self->owner();
  return;
}

sub commandEnabled {    # $bool ($command)
  my ( $class, $command ) = @_;
  return ( $command > 255 ) || $curCommandSet->has( $command );
}

sub disableCommands {    # void ($commands)
  my ( $class, $commands ) = @_;
  $commandSetChanged ||= !( $curCommandSet & $commands )->isEmpty();
  $curCommandSet->disableCmd( $commands );
  return;
}

sub enableCommands {    # void ($commands)
  my ( $class, $commands ) = @_;
  $commandSetChanged ||= ( $curCommandSet & $commands ) != $commands;
  $curCommandSet += $commands;
  return;
}

sub disableCommand {    # void ($command)
  my ( $class, $command ) = @_;
  $commandSetChanged ||= $curCommandSet->has( $command );
  $curCommandSet->disableCmd( $command );
  return;
}

sub enableCommand {    # void ($command)
  my ( $class, $command ) = @_;
  $commandSetChanged ||= !$curCommandSet->has( $command );
  $curCommandSet += $command;
  return;
}

sub getCommands {    # void ($commands)
  my ( $class, $commands ) = @_;
  $commands = $curCommandSet;
  return;
}

sub setCommands {    # void ($commands)
  my ( $class, $commands ) = @_;
  $commandSetChanged ||= $curCommandSet != $commands;
  $curCommandSet = $commands;
  return;
}

sub setCmdState {    # void ($commands, $enable)
  my ( $class, $commands, $enable ) = @_;
  $enable
    ? $class->enableCommands( $commands )
    : $class->disableCommands( $commands );
  return;
}

sub endModal {    # void ($command)
  my ( $self, $command ) = @_;
  if ( $self->TopView() ) {
    $self->TopView()->endModal( $command );
  }
  return;
}

sub execute {    # void ()
  return CM_CANCEL;
}

sub getColor {    # $int ($color)
  my ( $self, $color ) = @_;
  my $colorPair = $color >> 8;

  if ( $colorPair != 0 ) {
    $colorPair = $self->mapColor( $colorPair ) << 8;
  }

  $colorPair |= $self->mapColor( $color & 0xFF );

  return $colorPair;
} #/ sub getColor

my $palette = TPalette->new( data => "\0", size => 0 );
sub getPalette {    # $palette ()
  my $self = shift;
  return $palette->clone();
}

sub mapColor {    # $int ($color)
  my ( $self, $color ) = @_;

  return $errorAttr
    unless $color;

  my $cur = $self;
  do {
    my $p = $cur->getPalette();
    if ( $p->at( 0 ) ) {
      if ( $color > $p->at( 0 ) ) {
        return $errorAttr;
      }
      $color = $p->at( $color );
      return $errorAttr
        unless $color;
    }
    $cur = $cur->owner();
  } while ( $cur );

  return $color;
} #/ sub mapColor

sub getState {    # $bool ($aState)
  my ( $self, $aState ) = @_;
  return ( $self->{state} & $aState ) == $aState;
}

sub select {    # void ()
  my $self = shift;
  return
    unless $self->{options} & OF_SELECTABLE;
  if ( $self->{options} & OF_TOP_SELECT ) {
    $self->makeFirst();
  }
  elsif ( $self->owner() ) {
    $self->owner()->setCurrent( $self, NORMAL_SELECT );
  }
  return;
} #/ sub select

sub setState {    # void ($aState, $enable)
  my ( $self, $aState, $enable ) = @_;

  if ( $enable ) {
    $self->{state} |= $aState;
  }
  else {
    $self->{state} &= ~$aState;
  }

  return
    unless $self->owner();

  SWITCH: for ( $aState ) {
    $_ == SF_VISIBLE and do {
      if ( $self->owner()->{state} & SF_EXPOSED ) {
        $self->setState( SF_EXPOSED, $enable );
      }
      if ( $enable ) {
        $self->drawShow( undef );
      }
      else {
        $self->drawHide( undef );
      }
      if ( $self->{options} & OF_SELECTABLE ) {
        $self->owner()->resetCurrent();
      }
      last;
    };
    $_ == SF_CURSOR_VIS || $_ == SF_CURSOR_INS and do {
      $self->drawCursor();
      last;
    };
    $_ == SF_SHADOW and do {
      $self->drawUnderView( !!1, undef );
      last;
    };
    $_ == SF_FOCUSED and do {
      $self->resetCursor();
      message(
        $self->owner(),
        EV_BROADCAST,
        $enable ? CM_RECEIVED_FOCUS : CM_RELEASED_FOCUS,
        $self
      );
      last;
    };
  } #/ SWITCH: for ( $aState )
  return;
} #/ sub setState

sub keyEvent {    # void ($event)
  my ( $self, $event ) = @_;
  do {
    $self->getEvent( $event );
  } while ( $event->{what} != EV_KEY_DOWN );
  return;
}

sub mouseEvent { # bool ($event, $mask)
  my ( $self, $event, $mask ) = @_;
  do {
    $self->getEvent( $event );
  } while ( !( $event->{what} & ( $mask | EV_MOUSE_UP ) ) );

  return $event->{what} != EV_MOUSE_UP;
}

sub makeGlobal {    # $point ($source)
  my ( $self, $source ) = @_;
  my $temp = $source + $self->{origin};
  my $cur  = $self;
  while ( $cur->owner() ) {
    $cur = $cur->owner();
    $temp += $cur->{origin};
  }
  return $temp;
} #/ sub makeGlobal

sub makeLocal {    # $point ($source)
  my ( $self, $source ) = @_;
  my $temp = $source - $self->{origin};
  my $cur  = $self;
  while ( $cur->owner() ) {
    $cur = $cur->owner();
    $temp -= $cur->{origin};
  }
  return $temp;
} #/ sub makeLocal

sub nextView {    # $view ()
  no warnings 'uninitialized';
  my $self = shift;
  return $self == $self->owner()->last() ? undef : $self->next();
}

sub prevView {    # $view ()
  no warnings 'uninitialized';
  my $self = shift;
  return $self == $self->owner()->first() ? undef : $self->prev();
}

sub prev {    # $view ()
  no warnings 'uninitialized';
  my $self = shift;
  my $res  = $self;
  while ( $res->next() != $self ) {
    $res = $res->next();
  }
  return $res;
}

sub next {    # $view ()
  my $self = shift;
  if ( @_ ) {
    my $view = shift;
    return undef 
      if STRICT && !ref $view;
    my $id = id $view;
    $self->{next} = $id;
    $REF{ $id } = $view;
  }
  return $REF{ $self->{next} };
}

sub makeFirst {    # $void ()
  my $self = shift;
  $self->putInFrontOf($self->owner()->first());
  return;
}

sub putInFrontOf {    # void ($target)
  no warnings 'uninitialized';
  my ( $self, $target ) = @_;

  if ( $self->owner()
    && $target != $self
    && $target != $self->nextView()
    && ( !$target || $target->owner() == $self->owner() ) )
  {
    if ( !( $self->{state} & SF_VISIBLE ) ) {
      $self->owner()->removeView( $self );
      $self->owner()->insertView( $self, $target );
    }
    else {
      my $lastView = $self->nextView();
      my $p        = $target;
      while ( $p && $p != $self ) {
        $p = $p->nextView();
      }
      $lastView = $target if !$p;
      $self->{state} &= ~SF_VISIBLE;
      $self->drawHide( $lastView ) if $lastView == $target;
      $self->owner()->removeView( $self );
      $self->owner()->insertView( $self, $target );
      $self->{state} |= SF_VISIBLE;
      $self->drawShow( $lastView )   if $lastView != $target;
      $self->owner()->resetCurrent() if $self->{options} & OF_SELECTABLE;
    } #/ else [ if ( !( $self->{state}...))]
  } #/ if ( $self->owner() &&...)
  return;
} #/ sub putInFrontOf

sub TopView {    # $view ()
  my $self = shift;
  return $TheTopView
    if $TheTopView;

  my $p = $self;
  while ( $p && !( $p->{state} & SF_MODAL ) ) {
    $p = $p->owner();
  }
  return $p;
} #/ sub TopView

# The L</writeBuf>, L</writeChar>, L</writeLine> and L</writeStr> methods are a 
# port of the assembler code of I<tvwrite.asm>.
#
# The following code base was originally written by Jörn Sierwald in C++ and 
# ported now to Perl.

my $staticVars1 = [];
my ( $writeViewRec1, $writeViewRec2 );

$writeViewRec1 = sub {    # void ($x1, $x2, $p, $shadowCounter)
  my ( $self, $x1, $x2, $p, $shadowCounter ) = @_;
  while ( 1 ) {
    $p = $p->next();
    if ( $p == $staticVars2->{target} ) {    # run completed
      # write it!
      my $owner = $p->owner();
      if ( $owner->{buffer} ) {
        my $n   = $x2 - $x1;
        my $dst = $owner->{size}{x} * $staticVars2->{y} + $x1;
        my $src = $x1 - $staticVars2->{offset};

        if ( $shadowCounter == 0 ) {

          # writes a row of data to the screen
          splice(
            @{ $owner->{buffer} }, $dst, $n,
            $staticVars1->[ $src .. $n ]
          );
        }
        else {    # paint shadow attr
          while ( $n-- ) {
            my $cell = ( $staticVars1->[ $src++ ] & 0xff ) 
                     | ( $shadowAttr << 8 );

            # writes a character on the screen
            $owner->{buffer}->[ $dst++ ] = $cell;
          }
        }
      } #/ if ( $owner->{buffer} )
      $self->$writeViewRec2( $x1, $x2, $owner, $shadowCounter )
        if !$owner->{lockFlag};
      return;
    } #/ if ( $p eq $staticVars2...)

    next    # no overlapping
      if !( $p->{state} & SF_VISIBLE )
      || $staticVars2->{y} < $p->{origin}{y};

    # overlapping possible
    if ( $staticVars2->{y} < $p->{origin}{y} + $p->{size}{y} ) {
      if ( $x1 < $p->{origin}{x} ) {    # starts left of view
        next                             # left complete
          if $x2 <= $p->{origin}{x};
        $self->$writeViewRec1( $x1, $p->{origin}{x}, $p, $shadowCounter );
        $x1 = $p->{origin}{x};
      }
      my $bx = $p->{origin}{x} + $p->{size}{x};

      return    # completely covered
        if $x2 <= $bx;

      $x1 = max( $x1, $bx );
      $bx += $shadowSize->{x};

      # could possibly be in the shade
      next      # 1st row has no shade
        if !( $p->{state} & SF_SHADOW )
        || $staticVars2->{y} < $p->{origin}{y} + $shadowSize->{y};
      next      # right complete
        if $x1 >= $bx;
      $shadowCounter++;
      next      # everything in the shade
        if $x2 <= $bx;

      # split shadow part, right next to it
      $self->$writeViewRec1( $x1, $bx, $p, $shadowCounter );
      $x1 = $bx;
      $shadowCounter--;
      next;
    } #/ if ( $staticVars2->{y}...)
    next    # too far down
      if !( $p->{state} & SF_SHADOW )
      || $staticVars2->{y} >=
        $p->{origin}{y} + $p->{size}{y} + $shadowSize->{y};
    my $bx = $p->{origin}{x} + $shadowSize->{x};    # in the y-shadow?
    if ( $x1 < $bx ) {
      next                                           # left complete
        if $x2 <= $bx;
      $self->$writeViewRec1( $x1, $bx, $p, $shadowCounter );
      $x1 = $bx;
    }
    $bx += $p->{size}{x};
    next
      if $x1 >= $bx;
    $shadowCounter++;
    next    # everything in the shade
      if $x2 <= $bx;

    # split shadow part, right next to it
    $self->$writeViewRec1( $x1, $bx, $p, $shadowCounter );
    $x1 = $bx;
    $shadowCounter--;
  } #/ while ( 1 )
}; #/ $writeViewRec1 = sub

$writeViewRec2 = sub {
  my ( $self, $x1, $x2, $p, $shadowCounter ) = @_;
  my $owner = $p->owner();
  return
    if !( $p->{state} & SF_VISIBLE )
    || !$owner;

  my $savedStatics = {%$staticVars2};

  $staticVars2->{y}      += $p->{origin}{y};
  $x1                    += $p->{origin}{x};
  $x2                    += $p->{origin}{x};
  $staticVars2->{offset} += $p->{origin}{x};
  $staticVars2->{target} = $p;

  if ( $staticVars2->{y} < $owner->{clip}{a}{y}
    || $staticVars2->{y} >= $owner->{clip}{b}{y}
  ) {
    $staticVars2 = {%$savedStatics};
    return;
  }
  $x1 = max( $x1, $owner->{clip}{a}{x} );
  $x2 = min( $x2, $owner->{clip}{b}{x} );
  if ( $x1 >= $x2 ) {
    $staticVars2 = {%$savedStatics};
    return;
  }

  $self->$writeViewRec1( $x1, $x2, $owner->last(), $shadowCounter );
  $staticVars2 = {%$savedStatics};
  return;
}; #/ sub

my $writeView = sub {
  my ($self, $x1, $x2, $y, $buf) = @_;
  return 
    if $y < 0 || $y >= $self->{size}{y};
  $x1 = 0 
    if $x1 < 0;
  $x2 = $self->{size}{x} if $x2 > $self->{size}{x};
  return 
    if $x1 >= $x2;
  $staticVars2->{offset} = $x1;
  $staticVars1 = $buf;
  $staticVars2->{y} = $y;
  $self->$writeViewRec2($x1, $x2, $self, 0);
  return;
};

sub writeBuf {    # void ($x, $y, $w, $h, $b)
  no warnings 'uninitialized';
  my ( $self, $x, $y, $w, $h, $b ) = @_;
  for ( my $i = 0 ; $i < $h ; $i++ ) {
    $self->$writeView( $x, $x + $w, $y + $i, \ splice( @$b, $w * $i ) );
  }
  return;
}

sub writeChar {    # void ($x, $y, $c, $color, $count)
  my ( $self, $x, $y, $c, $color, $count ) = @_;
  my $b      = [];
  my $myChar = ( $self->mapColor( $color ) << 8 ) + ( ord( $c ) & 0xff );
  my $count2 = $count;
  $x = 0
    if $x < 0;
  return
    if $x + $count > MAX_VIEW_WIDTH;
  my $p = 0;
  while ( $count-- ) {
    $b->[ $p++ ] = $myChar;
  }
  $self->$writeView( $x, $x + $count2, $y, $b );
  return;
} #/ sub writeChar

sub writeLine {    # void ($x, $y, $w, $h, $b)
  my ( $self, $x, $y, $w, $h, $b ) = @_;
  return
    if $h == 0;
  for ( my $i = 0 ; $i < $h ; $i++ ) {
    $self->$writeView( $x, $x + $w, $y + $i, $b );
  }
  return;
}

sub writeStr {    # void ($x, $y, $str, $color)
  my ( $self, $x, $y, $str, $color ) = @_;
  return
    unless $str;
  my $l = length( $str );
  return
    if $l == 0;
  $l = MAX_VIEW_WIDTH
    if $l > MAX_VIEW_WIDTH;
  my $l2      = $l;
  my $myColor = $self->mapColor( $color ) << 8;
  my $b       = [];
  my $p       = 0;
  while ( $l-- ) {
    $b->[$p++] = $myColor + ( ord( substr( $str, $p, 1 ) ) & 0xff );
  }
  $self->$writeView( $x, $x + $l2, $y, $b );
  return;
} #/ sub writeStr

sub owner {    # $group ()
  my $self = shift;
  if ( @_ ) {
    my $group = shift;
    return undef 
      if STRICT && !ref $group;
    my $id = id $group;
    $self->{owner} = $id;
    $REF{ $id } = $group;
  }
  return $REF{ $self->{owner} };
}

sub shutDown {    # void ()
  my $self = shift;
  $self->hide();
  if ( $self->owner() ) {
    $self->owner()->remove( $self );
  }
  $self->SUPER::shutDown();
  return;
}

1
