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
  new_TView
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use List::Util qw( min max );
use Scalar::Util qw( 
  blessed 
  weaken
  looks_like_number
  readonly
);

use TV::Const qw( INT_MAX );
use TV::Objects::Object;
use TV::Objects::DrawBuffer;
use TV::Objects::Point;
use TV::Objects::Rect;
use TV::Drivers::Const qw(
  :evXXXX
  :kbXXXX
);
use TV::Drivers::Event;
use TV::Views::Const qw(
  maxViewWidth
  :phaseType
  :selectMode
  :cmXXXX
  :dmXXXX
  :gfXXXX
  :hcXXXX
  :ofXXXX
  :sfXXXX
);
use TV::Views::CommandSet;
use TV::Views::Palette;
use TV::Views::Util qw( message );
use TV::toolkit;

require TV::Views::View::Cursor;
require TV::Views::View::Exposed;
require TV::Views::View::Write;

sub TView() { __PACKAGE__ }
sub name() { 'TView' }
sub new_TView { __PACKAGE__->from(@_) }

extends TObject;

# declare global variables
our $shadowSize        = TPoint->new( x => 2, y => 1 );
our $shadowAttr        = 0x08;
our $showMarkers       = !!0;
our $errorAttr         = 0xcf;
our $commandSetChanged = !!0;
our $curCommandSet     = do {    # initCommands
  my $temp = TCommandSet->new();
  for ( my $i = 0 ; $i < 256 ; $i++ ) {
    $temp->enableCmd( $i );
  }
  $temp->disableCmd( cmZoom );
  $temp->disableCmd( cmClose );
  $temp->disableCmd( cmResize );
  $temp->disableCmd( cmNext );
  $temp->disableCmd( cmPrev );
  $temp;
};

# import global variables
use vars qw(
  $TheTopView
); 
{
  *TheTopView = \$TV::Views::Group::TheTopView;
}

# declare attributes
slots owner     => ( is => 'bare' );
slots next      => ( is => 'bare' );
slots options   => ( default => sub { 0 } );
slots state     => ( default => sub { sfVisible } );
slots growMode  => ( default => sub { 0 } );
slots dragMode  => ( default => sub { dmLimitLoY } );
slots helpCtx   => ( default => sub { hcNoContext } );
slots eventMask => ( default => sub { evMouseDown | evKeyDown | evCommand } );
slots size      => ( default => sub { TPoint->new() } );
slots origin    => ( default => sub { TPoint->new() } );
slots cursor    => ( default => sub { TPoint->new() } );

# predeclare private methods
my (
  $moveGrow,
  $change,
  $writeView,
);

my $lock_value = sub {
  Internals::SvREADONLY( $_[0] => 1 )
    if exists &Internals::SvREADONLY;
};

my $unlock_value = sub {
  Internals::SvREADONLY( $_[0] => 0 )
    if exists &Internals::SvREADONLY;
};

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'required' arguments
  assert ( blessed $args{bounds} );
  return \%args;
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( blessed $self );
  $lock_value->( $self->{owner} ) if STRICT;
  $lock_value->( $self->{next} )  if STRICT;
  $self->setBounds( $args->{bounds} );
  return;
} #/ sub BUILD

sub from {    # $obj ($bounds)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 1 );
  return $class->new( bounds => $_[0] );
}

sub DEMOLISH {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $unlock_value->( $self->{owner} ) if STRICT;
  $unlock_value->( $self->{next} )  if STRICT;
  return;
}

sub sizeLimits {    # void ($min, $max)
  my ( $self, $min, $max ) = @_;
  assert ( blessed $self );
  assert ( blessed $min );
  assert ( blessed $max );
  $min->{x} = $min->{y} = 0;
  if ( !( $self->{growMode} & gfFixed ) && $self->{owner} ) {
    $max->{x} = $self->{owner}{size}{x};
    $max->{y} = $self->{owner}{size}{y};
  }
  else {
    $max->{x} = $max->{y} = INT_MAX;
  }
  return;
} #/ sub sizeLimits

sub getBounds {    # $rect ()
  my $self = shift;
  assert ( blessed $self );
  return TRect->new(
    p1 => $self->{origin},
    p2 => $self->{origin} + $self->{size},
  );
}

sub getExtent {    # $rect ()
  my $self = shift;
  assert ( blessed $self );
  return TRect->new(
    ax => 0,
    ay => 0,
    bx => $self->{size}{x},
    by => $self->{size}{y},
  );
}

sub getClipRect {    # $rect ()
  my $self = shift;
  assert ( blessed $self );
  my $clip = $self->getBounds();
  if ( $self->{owner} ) {
    $clip->intersect( $self->{owner}{clip} );
  }
  $clip->move( -$self->{origin}{x}, -$self->{origin}{y} );
  return $clip;
}

sub mouseInView {    # $bool ($mouse)
  my ( $self, $mouse ) = @_;
  assert ( blessed $self );
  assert ( blessed $mouse );
  $mouse = $self->makeLocal( $mouse->clone() );
  my $r = $self->getExtent();
  return $r->contains( $mouse );
}

sub containsMouse {    # $bool ($event)
  my ( $self, $event ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  return ( $self->{state} & sfVisible )
    && $event->{mouse}
    && $self->mouseInView( $event->{mouse}{where} );
}

# Define the range function
my $range = sub {    # $ ($val, $min, $max)
  my ( $val, $min, $max ) = @_;
  return ( $val < $min ) ? $min : ( ( $val > $max ) ? $max : $val );
};

sub locate {    # void ($bounds)
  my ( $self, $bounds ) = @_;
  assert ( blessed $self );
  assert ( ref $bounds );
  my ( $min,  $max ) = ( TPoint->new(), TPoint->new() );
  $self->sizeLimits( $min, $max );
  $bounds->{b}{x} = $bounds->{a}{x} +
    $range->( $bounds->{b}{x} - $bounds->{a}{x}, $min->{x}, $max->{x} );
  $bounds->{b}{y} = $bounds->{a}{y} +
    $range->( $bounds->{b}{y} - $bounds->{a}{y}, $min->{y}, $max->{y} );
  my $r = $self->getBounds();
  if ( $bounds != $r ) {
    $self->changeBounds( $bounds );
    if ( $self->{owner} && ( $self->{state} & sfVisible ) ) {
      if ( $self->{state} & sfShadow ) {
        $r->Union( $bounds );
        $r->{b} += $shadowSize;
      }
      $self->drawUnderRect( $r, 0 );
    }
  } #/ if ( $bounds != $r )
  return;
} #/ sub locate

my ( $goLeft, $goRight, $goUp, $goDown, $goCtrlLeft, $goCtrlRight );

sub dragView {    # void ($event, $mode, $limits, $minSize, $maxSize)
  my ( $self, $event, $mode, $limits, $minSize, $maxSize ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  assert ( looks_like_number $mode );
  assert ( blessed $limits );
  assert ( blessed $minSize );
  assert ( blessed $maxSize );
  my $saveBounds;

  my ( $p, $s );
  $self->setState( sfDragging, !!1 );

  if ( $event->{what} == evMouseDown ) {
    if ( $mode & dmDragMove ) {
      $p = $self->{origin} - $event->{mouse}{where};
      do {
        $event->{mouse}{where} += $p;
        $self->$moveGrow(
          $event->{mouse}{where}, $self->{size}, $limits, $minSize,
          $maxSize, $mode
        );
      } while ( $self->mouseEvent( $event, evMouseMove ) );
    } #/ if ( $mode & dmDragMove)
    else {
      $p = $self->{size} - $event->{mouse}{where};
      do {
        $event->{mouse}{where} += $p;
        $self->$moveGrow(
          $self->{origin}, $event->{mouse}{where}, $limits, $minSize,
          $maxSize,        $mode
        );
      } while ( $self->mouseEvent( $event, evMouseMove ) );
    } #/ else [ if ( $mode & dmDragMove)]
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
        $_ == kbLeft and do {
          $self->$change( $mode, $goLeft, $p, $s, 
            $event->{keyDown}{controlKeyState} );
          last;
        };
        $_ == kbRight and do {
          $self->$change( $mode, $goRight, $p, $s, 
            $event->{keyDown}{controlKeyState} );
          last;
        };
        $_ == kbUp and do {
          $self->$change( $mode, $goUp, $p, $s, 
            $event->{keyDown}{controlKeyState} );
          last;
        };
        $_ == kbDown and do {
          $self->$change( $mode, $goDown, $p, $s, 
            $event->{keyDown}{controlKeyState} );
          last;
        };
        $_ == kbCtrlLeft and do {
          $self->$change(
            $mode, $goCtrlLeft, $p, $s,
            $event->{keyDown}{controlKeyState}
          );
          last;
        };
        $_ == kbCtrlRight and do {
          $self->$change(
            $mode, $goCtrlRight, $p, $s,
            $event->{keyDown}{controlKeyState}
          );
          last;
        };
        $_ == kbHome and do {
          $p->{x} = $limits->{a}{x};
          last;
        };
        $_ == kbEnd and do {
          $p->{x} = $limits->{b}{x} - $s->{x};
          last;
        };
        $_ == kbPgUp and do {
          $p->{y} = $limits->{a}{y};
          last;
        };
        $_ == kbPgDn and do {
          $p->{y} = $limits->{b}{y} - $s->{y};
          last;
        };
      }
      $self->$moveGrow( $p, $s, $limits, $minSize, $maxSize, $mode );
    } while ( $event->{keyDown}{keyCode} != kbEsc
           && $event->{keyDown}{keyCode} != kbEnter 
          );
    if ( $event->{keyDown}{keyCode} == kbEsc ) {
      $self->locate( $saveBounds );
    }
  } #/ else [ if ( $event->{what} ==...)]
  $self->setState( sfDragging, !!0 );
} #/ sub dragView

my $grow;

sub calcBounds {    # void ($bounds, $delta);
  my ( $self, undef, $delta ) = @_;
  alias: for my $bounds ( $_[1] ) {
  assert ( blessed $self );
  assert ( ref $bounds );
  assert ( ref $delta );

  my ( $s, $d );

  $grow ||= sub {
    if ( $self->{growMode} & gfGrowRel ) {
      $_[0] = ( $_[0] * $s + ( ( $s - $d ) >> 1 ) ) / ( $s - $d );
    }
    else {
      $_[0] += $d;
    }
  };

  $bounds = $self->getBounds();

  $s = $self->{owner}{size}{x};
  $d = $delta->{x};

  if ( $self->{growMode} & gfGrowLoX ) {
    $grow->( $bounds->{a}{x} );
  }

  if ( $self->{growMode} & gfGrowHiX ) {
    $grow->( $bounds->{b}{x} );
  }

  $s = $self->{owner}{size}{y};
  $d = $delta->{y};

  if ( $self->{growMode} & gfGrowLoY ) {
    $grow->( $bounds->{a}{y} );
  }

  if ( $self->{growMode} & gfGrowHiY ) {
    $grow->( $bounds->{b}{y} );
  }

  my ( $minLim, $maxLim ) = ( TPoint->new(), TPoint->new() );
  $self->sizeLimits( $minLim, $maxLim );
  $bounds->{b}{x} = $bounds->{a}{x} +
    $range->( $bounds->{b}{x} - $bounds->{a}{x}, $minLim->{x}, $maxLim->{x} );
  $bounds->{b}{y} = $bounds->{a}{y} +
    $range->( $bounds->{b}{y} - $bounds->{a}{y}, $minLim->{y}, $maxLim->{y} );
  return;
  } #/ alias
} #/ sub calcBounds

sub changeBounds {    # void ($bounds)
  my ( $self, $bounds ) = @_;
  assert ( blessed $self );
  assert ( ref $bounds );
  $self->setBounds( $bounds );
  $self->drawView();
  return;
}

sub growTo {    # void ($x, $y)
  my ( $self, $x, $y ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $x );
  assert ( looks_like_number $y );
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
  assert ( blessed $self );
  assert ( looks_like_number $x );
  assert ( looks_like_number $y );
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
  assert ( blessed $self );
  assert ( blessed $bounds );
  $self->{origin} = $bounds->{a}->clone;
  $self->{size}   = $bounds->{b} - $bounds->{a};
  return;
}

sub getHelpCtx {    # $int ()
  my $self = shift;
  assert ( blessed $self );
  if ( $self->{state} & sfDragging ) {
    return hcDragging;
  }
  return $self->{helpCtx};
}

sub valid {    # $bool ($command)
  assert ( blessed shift );
  assert ( looks_like_number shift );
  return !!1;
}

sub hide {    # void ()
  my $self = shift;
  assert ( blessed $self );
  if ( $self->{state} & sfVisible ) {
    $self->setState( sfVisible, !!0 );
  }
  return;
}

sub show {    # void ()
  my $self = shift;
  assert ( blessed $self );
  if ( ( $self->{state} & sfVisible ) == 0 ) {
    $self->setState( sfVisible, !!1 );
  }
  return;
}

sub draw {    # void ()
  my $self = shift;
  assert ( blessed $self );
  my $b = TDrawBuffer->new();

  $b->moveChar( 0, ' ', $self->getColor( 1 ), $self->{size}{x} );
  $self->writeLine( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  return;
}

sub drawView {    # void ()
  my $self = shift;
  assert ( blessed $self );
  if ( $self->exposed() ) {
    $self->draw();
    $self->drawCursor();
  }
  return;
}

sub exposed {    # $bool ()
  my $self = shift;
  assert ( blessed $self );
  return TV::Views::View::Exposed::L0( $self );
}

sub focus {    # $bool ()
  my $self = shift;
  assert ( blessed $self );
  my $result = !!1;

  if ( !( $self->{state} & ( sfSelected | sfModal ) ) ) {
    if ( $self->{owner} ) {
      $result = $self->{owner}->focus();
      if ( $result ) {
        if ( !$self->{owner}{current}
          || !( $self->{owner}{current}{options} & ofValidate )
          || $self->{owner}{current}->valid( cmReleasedFocus ) )
        {
          $self->select();
        }
        else {
          return !!0;
        }
      } #/ if ( $result )
    } #/ if ( $self->{owner} )
  } #/ if ( !( $self->{state}...))
  return $result;
} #/ sub focus

sub hideCursor {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->setState( sfCursorVis, !!0 );
  return;
}

sub drawHide {    # void ($lastView|undef)
  my ( $self, $lastView ) = @_;
  assert ( blessed $self );
  assert ( !defined $lastView or blessed $lastView );
  assert ( @_ == 2 );
  $self->drawCursor();
  $self->drawUnderView( ($self->{state} & sfShadow) != 0, $lastView );
  return;
}

sub drawShow {    # void ($lastView|undef)
  my ( $self, $lastView ) = @_;
  assert ( blessed $self );
  assert ( !defined $lastView or blessed $lastView );
  assert ( @_ == 2 );
  $self->drawView();
  if ( $self->{state} & sfShadow ) {
    $self->drawUnderView( !!1, $lastView );
  }
  return;
}

sub drawUnderRect {    # void ($r, $lastView|undef)
  my ( $self, $r, $lastView ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  assert ( !defined $lastView or blessed $lastView );
  assert ( @_ == 3 );
  $self->{owner}{clip}->intersect( $r );
  $self->{owner}->drawSubViews( $self->nextView(), $lastView );
  $self->{owner}{clip} = $self->{owner}->getExtent();
  return;
}

sub drawUnderView {    # void ($doShadow, $lastView|undef)
  my ( $self, $doShadow, $lastView ) = @_;
  assert ( blessed $self );
  assert ( !defined $doShadow or !ref $doShadow );
  assert ( !defined $lastView or blessed $lastView );
  assert ( @_ == 3 );
  my $r = $self->getBounds();
  if ( $doShadow ) {
    $r->{b} += $shadowSize;
  }
  $self->drawUnderRect( $r, $lastView );
  return;
}

sub dataSize {    # $size ()
  assert ( blessed shift );
  return 0;
}

sub getData {    # void ($rec)
  assert ( blessed shift );
  return;
}

sub setData {    # void ($rec)
  assert ( blessed shift );
  return;
}

sub awaken {    # void ()
  assert ( blessed shift );
  return;
}

sub blockCursor {    # void ()
  my $self = shift;
  $self->setState( sfCursorIns, !!1 );
  return;
}

sub normalCursor {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->setState( sfCursorIns, !!0 );
  return;
}

sub resetCursor {    # void ()
  my $self = shift;
  assert ( blessed $self );
  TV::Views::View::Cursor::resetCursor( $self );
  return;
}

sub setCursor {    # void ($x, $y)
  my ( $self, $x, $y ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $x );
  assert ( looks_like_number $y );
  $self->{cursor}{x} = $x;
  $self->{cursor}{y} = $y;
  $self->drawCursor();
  return;
}

sub showCursor {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->setState( sfCursorVis, !!1 );
  return;
}

sub drawCursor {    # void ()
  my $self = shift;
  assert ( blessed $self );
  if ( $self->{state} & sfFocused ) {
    $self->resetCursor();
  }
  return;
}

sub clearEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  $event->{what}    = evNothing;
  $event->{message} = MessageEvent->new( infoPtr => $self );
  return;
}

sub eventAvail {    # $bool ()
  my $self  = shift;
  assert ( blessed $self );
  my $event = TEvent->new();
  $self->getEvent( $event );
  if ( $event->{what} != evNothing ) {
    $self->putEvent( $event );
  }
  return $event->{what} != evNothing;
}

sub getEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  if ( $self->{owner} ) {
    $self->{owner}->getEvent( $event );
  }
  return;
}

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  if ( $event->{what} == evMouseDown ) {
    if ( !( $self->{state} & ( sfSelected | sfDisabled ) )
      && ( $self->{options} & ofSelectable )
    ) {
      if ( !$self->focus() || !( $self->{options} & ofFirstClick ) ) {
        $self->clearEvent( $event );
      }
    }
  }
  return;
} #/ sub handleEvent

sub putEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  $self->{owner}->putEvent( $event )
    if $self->{owner};
  return;
}

sub commandEnabled {    # $bool ($command)
  my ( $class, $command ) = @_;
  assert ( $class );
  assert ( looks_like_number $command );
  return ( $command > 255 ) || $curCommandSet->has( $command );
}

sub disableCommands {    # void ($commands)
  my ( $class, $commands ) = @_;
  assert ( $class );
  assert ( blessed $commands );
  $commandSetChanged ||= !( $curCommandSet & $commands )->isEmpty();
  $curCommandSet->disableCmd( $commands );
  return;
}

sub enableCommands {    # void ($commands)
  my ( $class, $commands ) = @_;
  assert ( $class );
  assert ( blessed $commands );
  $commandSetChanged ||= ( $curCommandSet & $commands ) != $commands;
  $curCommandSet += $commands;
  assert ( blessed $curCommandSet );
  return;
}

sub disableCommand {    # void ($command)
  my ( $class, $command ) = @_;
  assert ( $class );
  assert ( looks_like_number $command );
  $commandSetChanged ||= $curCommandSet->has( $command );
  $curCommandSet->disableCmd( $command );
  return;
}

sub enableCommand {    # void ($command)
  my ( $class, $command ) = @_;
  assert ( $class );
  assert ( looks_like_number $command );
  $commandSetChanged ||= !$curCommandSet->has( $command );
  $curCommandSet += $command;
  return;
}

sub getCommands {    # void ($commands)
  my ( $class, $commands ) = @_;
  assert ( $class );
  assert ( blessed $commands );
  $commands = $curCommandSet;
  return;
}

sub setCommands {    # void ($commands)
  my ( $class, $commands ) = @_;
  assert ( $class );
  assert ( blessed $commands );
  $commandSetChanged ||= $curCommandSet != $commands;
  $curCommandSet = $commands;
  return;
}

sub setCmdState {    # void ($commands, $enable)
  my ( $class, $commands, $enable ) = @_;
  assert ( $class );
  assert ( blessed $commands );
  assert ( !defined $enable or !ref $enable );
  assert ( @_ == 3 );
  $enable
    ? $class->enableCommands( $commands )
    : $class->disableCommands( $commands );
  return;
}

sub endModal {    # void ($command)
  my ( $self, $command ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $command );
  if ( $self->TopView() ) {
    $self->TopView()->endModal( $command );
  }
  return;
}

sub execute {    # $cmd ()
  assert ( blessed shift );
  return cmCancel;
}

sub getColor {    # $int ($color)
  my ( $self, $color ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $color );
  my $colorPair = $color >> 8;

  if ( $colorPair != 0 ) {
    $colorPair = $self->mapColor( $colorPair ) << 8;
  }

  $colorPair |= $self->mapColor( $color & 0xff );

  return $colorPair;
} #/ sub getColor

my $palette; 
sub getPalette {    # $palette ()
  my $self = shift;
  assert ( blessed $self );
  $palette ||= TPalette->new( data => "\0", size => 0 );
  return $palette->clone();
}

sub mapColor {    # $int ($color)
  my ( $self, $color ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $color );

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
    $cur = $cur->{owner};
  } while ( $cur );

  return $color;
} #/ sub mapColor

sub getState {    # $bool ($aState)
  my ( $self, $aState ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aState );
  return ( $self->{state} & $aState ) == $aState;
}

sub select {    # void ()
  my $self = shift;
  assert ( blessed $self );
  return
    unless $self->{options} & ofSelectable;
  if ( $self->{options} & ofTopSelect ) {
    $self->makeFirst();
  }
  elsif ( $self->{owner} ) {
    $self->{owner}->setCurrent( $self, normalSelect );
  }
  return;
} #/ sub select

sub setState {    # void ($aState, $enable)
  my ( $self, $aState, $enable ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aState );
  assert ( !defined $enable or !ref $enable );
  assert ( @_ == 3 );

  if ( $enable ) {
    $self->{state} |= $aState;
  }
  else {
    $self->{state} &= ~$aState;
  }

  return
    unless $self->{owner};

  SWITCH: for ( $aState ) {
    $_ == sfVisible and do {
      if ( $self->{owner}{state} & sfExposed ) {
        $self->setState( sfExposed, $enable );
      }
      if ( $enable ) {
        $self->drawShow( undef );
      }
      else {
        $self->drawHide( undef );
      }
      if ( $self->{options} & ofSelectable ) {
        $self->{owner}->resetCurrent();
      }
      last;
    };
    $_ == sfCursorVis || $_ == sfCursorIns and do {
      $self->drawCursor();
      last;
    };
    $_ == sfShadow and do {
      $self->drawUnderView( !!1, undef );
      last;
    };
    $_ == sfFocused and do {
      $self->resetCursor();
      message(
        $self->{owner},
        evBroadcast,
        $enable ? cmReceivedFocus : cmReleasedFocus,
        $self
      );
      last;
    };
  } #/ SWITCH: for ( $aState )
  return;
} #/ sub setState

sub keyEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  do {
    $self->getEvent( $event );
  } while ( $event->{what} != evKeyDown );
  return;
}

sub mouseEvent { # bool ($event, $mask)
  my ( $self, $event, $mask ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  assert ( looks_like_number $mask );
  do {
    $self->getEvent( $event );
  } while ( !( $event->{what} & ( $mask | evMouseUp ) ) );

  return $event->{what} != evMouseUp;
}

sub makeGlobal {    # $point ($source)
  my ( $self, $source ) = @_;
  assert ( blessed $self );
  assert ( blessed $source );
  my $temp = $source + $self->{origin};
  my $cur  = $self;
  while ( $cur->{owner} ) {
    $cur = $cur->{owner};
    $temp += $cur->{origin};
  }
  return $temp;
} #/ sub makeGlobal

sub makeLocal {    # $point ($source)
  my ( $self, $source ) = @_;
  assert ( blessed $self );
  assert ( blessed $source );
  my $temp = $source - $self->{origin};
  my $cur  = $self;
  while ( $cur->{owner} ) {
    $cur = $cur->{owner};
    $temp -= $cur->{origin};
  }
  return $temp;
} #/ sub makeLocal

sub nextView {    # $view|undef ()
  no warnings qw( uninitialized numeric );
  my $self = shift;
  assert ( blessed $self );
  return $self->{next}
    if $self->{owner}
    && $self != $self->{owner}{last};
  return undef;
}

sub prevView {    # $view|undef ()
  no warnings qw( uninitialized numeric );
  my $self = shift;
  assert ( blessed $self );
  return $self->prev()
    if $self->{owner} 
    && $self != $self->{owner}->first();
  return undef;
}

sub prev {    # $view|undef ()
  no warnings qw( uninitialized numeric );
  my $self = shift;
  assert ( blessed $self );
  my $res = $self;
  while ( $res && $res->{next} != $self ) {
    $res = $res->{next};
  }
  return $res;
}

sub next {    # $view (|$view|undef)
  my ( $self, $view ) = @_;
  assert ( blessed $self );
  assert ( !defined $view or blessed $view );
  if ( @_ == 2 ) {
    $unlock_value->( $self->{next} ) if STRICT;
    $self->{next} = $view;
    $lock_value->( $self->{next} ) if STRICT;
  }
  return $self->{next};
} #/ sub next

sub makeFirst {    # $void ()
  my $self = shift;
  assert ( blessed $self );
  $self->putInFrontOf( $self->{owner}->first() ) 
    if $self->{owner};
  return;
}

sub putInFrontOf {    # void ($target|undef)
  no warnings qw( uninitialized numeric );
  my ( $self, $target ) = @_;
  assert ( blessed $self );
  assert ( @_ == 2 );

  if ( $self->{owner}
    && $target != $self
    && $target != $self->nextView()
    && ( !$target || $target->{owner} == $self->{owner} ) )
  {
    if ( !( $self->{state} & sfVisible ) ) {
      $self->{owner}->removeView( $self );
      $self->{owner}->insertView( $self, $target );
    }
    else {
      my $lastView = $self->nextView();
      my $p        = $target;
      while ( $p && $p != $self ) {
        $p = $p->nextView();
      }
      $lastView = $target
        if !$p;
      $self->{state} &= ~sfVisible;
      $self->drawHide( $lastView )
        if $lastView == $target;
      $self->{owner}->removeView( $self );
      $self->{owner}->insertView( $self, $target );
      $self->{state} |= sfVisible;
      $self->drawShow( $lastView )
        if $lastView != $target;
      $self->{owner}->resetCurrent()
        if $self->{options} & ofSelectable;
    } #/ else [ if ( !( $self->{state}...))]
  } #/ if ( $self->{owner} &&...)
  return;
} #/ sub putInFrontOf

sub TopView {    # $view ()
  my $self = shift;
  assert ( blessed $self );
  return $TheTopView
    if $TheTopView;

  my $p = $self;
  while ( $p && !( $p->{state} & sfModal ) ) {
    $p = $p->{owner};
  }
  return $p;
} #/ sub TopView

sub writeBuf {    # void ($x, $y, $w, $h, $b)
  my ( $self, $x, $y, $w, $h, $b ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $x );
  assert ( looks_like_number $y );
  assert ( looks_like_number $w );
  assert ( looks_like_number $h );
  assert ( ref $b );
  while ( $h-- > 0 ) {
    $self->$writeView( $x, $y++, $w, $b );
    alias: $b = sub { \@_ }->( @$b[ $w .. $#$b ] );
  }
  return;
}

my $setCell = sub {    # void ($cell, $ch, $attr)
  $_[0] = ( ( $_[2] & 0xff ) << 8 ) | $_[1] & 0xff;
  return;
};

sub writeChar {    # void ($x, $y, $c, $color, $count)
  my ( $self, $x, $y, $c, $color, $count ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $x );
  assert ( looks_like_number $y );
  assert ( !ref $c and length $c );
  assert ( looks_like_number $color );
  assert ( looks_like_number $count );
  if ( $count > 0 ) {
    $setCell->( my $cell, ord( $c ), $color );
    my $buf = [ ( $cell ) x $count ];
    $self->$writeView( $x, $y, $count, $buf );
  }
  return;
}

sub writeLine {    # void ($x, $y, $w, $h, $b)
  my ( $self, $x, $y, $w, $h, $b ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $x );
  assert ( looks_like_number $y );
  assert ( looks_like_number $w );
  assert ( looks_like_number $h );
  assert ( ref $b );
  while ( $h-- > 0 ) {
    $self->$writeView( $x, $y++, $w, $b );
  }
  return;
}

sub writeStr {    # void ($x, $y, $str, $color)
  my ( $self, $x, $y, $str, $color ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $x );
  assert ( looks_like_number $y );
  assert ( !ref $str );
  assert ( looks_like_number $color );
  if ( $str ) {
    my $length = length( $str );
    if ( $length > 0 ) {
      my $attr = $self->mapColor( $color );
      my $buf  = [ ( 0 ) x maxViewWidth ];
      my $i    = 0;
      foreach my $c ( split //, $str ) {
        $setCell->( $buf->[$i], ord( $c ), $attr );
        $i++;
      }
      $self->$writeView( $x, $y, $length, $buf );
    } #/ if ( $length > 0 )
  } #/ if ( $str )
  return;
} #/ sub writeStr

sub owner {    # $group (|$group|undef)
  my ( $self, $group ) = @_;
  assert ( blessed $self );
  assert ( !defined $group or blessed $group );
  if ( @_ == 2 ) {
    $unlock_value->( $self->{owner} ) if STRICT;
    weaken $self->{owner}
      if $self->{owner} = $group;
    $lock_value->( $self->{owner} ) if STRICT;
  }
  return $self->{owner};
} #/ sub owner

sub shutDown {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->hide();
  if ( $self->{owner} ) {
    $self->{owner}->remove( $self );
  }
  $self->SUPER::shutDown();
  return;
}

$moveGrow = sub {
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

  if ( $mode & dmLimitLoX ) {
    $p->{x} = max( $p->{x}, $limits->{a}{x} );
  }
  if ( $mode & dmLimitLoY ) {
    $p->{y} = max( $p->{y}, $limits->{a}{y} );
  }
  if ( $mode & dmLimitHiX ) {
    $p->{x} = min( $p->{x}, $limits->{b}{x} - $s->{x} );
  }
  if ( $mode & dmLimitHiY ) {
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

$change = sub {    # void ($mode, $delta, $p, $s, $ctrlState)
  my ( $self, $mode, $delta, $p, $s, $ctrlState ) = @_;
  if ( ( $mode & dmDragMove ) && !( $ctrlState & !kbShift ) ) {
    $p += $delta;
  }
  elsif ( ( $mode & dmDragGrow ) && ( $ctrlState & kbShift ) ) {
    $s += $delta;
  }
  return;
}; #/ sub

$writeView = sub {    # void ($x, $y, $count, $b)
  my ( $self, $x, $y, $count, $b ) = @_;
  TV::Views::View::Write::L0( $self, $x, $y, $count, $b );
  return;
};

1
