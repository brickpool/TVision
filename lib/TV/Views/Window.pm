package TV::Views::Window;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TWindow
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
  weaken
);

use TV::App::Program;
use TV::Drivers::Const qw(
  :evXXXX
  :kbXXXX
);
use TV::Objects::Point;
use TV::Objects::Rect;
use TV::Views::Const qw(
  :cmXXXX
  :cpXXXX
  :gfXXXX
  :ofXXXX
  :sbXXXX
  :sfXXXX
  :wfXXXX
  wpBlueWindow
);
use TV::Views::CommandSet;
use TV::Views::Frame;
use TV::Views::Group;
use TV::Views::Palette;
use TV::Views::ScrollBar;
use TV::Views::WindowInit;
use TV::toolkit;

sub TWindow() { __PACKAGE__ }
sub name() { 'TWindow' }

extends ( TGroup, TWindowInit );

# declare global variables
our $minWinSize = TPoint->new( x => 16, y => 6 );

# import global variables
use vars qw(
  $appPalette
);
{
  no strict 'refs';
  *appPalette = \${ TProgram . '::appPalette' };
}

slots flags    => ( default => sub { wfMove | wfGrow | wfClose | wfZoom } );
slots zoomRect => ();
slots number   => ( default => sub { die 'required' } );
slots palette  => ();
slots frame    => ();
slots title    => ( default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'init_arg' is not equal to the field name
  $args{createFrame} = delete $args{cFrame};
  # TWindowInit->BUILDARGS is not called because arguments are not 'required'
  return TGroup->BUILDARGS( %args );
}

sub BUILD {    # void (| \%args)
  my $self = shift;
  assert ( blessed $self );
  $self->{zoomRect} = $self->getBounds();
  $self->{palette}  = wpBlueWindow;
  $self->{createFrame} ||= \&initFrame;

  $self->{state}   |= sfShadow;
  $self->{options} |= ofSelectable | ofTopSelect;
  $self->{growMode} = gfGrowAll | gfGrowRel;

  if ( $self->{createFrame}
    && ( $self->{frame} = $self->createFrame( $self->getExtent() ) )
  ) {
    $self->insert( $self->{frame} );
  }
  return;
} #/ sub new

sub DEMOLISH {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->{title} = undef;
  return;
}

sub close {    # void ()
  alias: for my $self ( $_[0] ) {    # Maybe we are destroying ourselves
  assert ( blessed $self );
  if ( $self->valid( cmClose ) ) {
    # so we don't try to use the frame after it's been deleted
    $self->{frame} = undef;
	  $self->destroy( $self );
  }
  return;
  } #/ alias
}

my ( $blue, $cyan, $gray, @palettes );
sub getPalette {    # $palette ()
  my $self = shift;
  assert ( blessed $self );
  $blue ||= TPalette->new(
    data => cpBlueWindow,
    size => length( cpBlueWindow ) 
  );
  $cyan ||= TPalette->new( 
    data => cpCyanWindow,
    size => length( cpCyanWindow ) 
  );
  $gray ||= TPalette->new( 
    data => cpGrayWindow,
    size => length( cpGrayWindow ) 
  );
  @palettes = ( $blue, $cyan, $gray ) unless @palettes;
  return $palettes[$appPalette]->clone();
} #/ sub getPalette

sub getTitle {    # $str ($maxSize)
  my ( $self, $maxSize ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $maxSize );
  return $self->{title};
}

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  my $limits = TRect->new();
  my ( $min, $max ) = ( TPoint->new(), TPoint->new() );

  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {
      $_ == cmResize and do {
        if ( $self->{flags} & ( wfMove | wfGrow ) ) {
          $limits = $self->owner->getExtent();
          $self->sizeLimits( $min, $max );
          $self->dragView( $event, 
            $self->{dragMode} | ( $self->{flags} & ( wfMove | wfGrow ) ), 
            $limits, $min, $max
          );
          $self->clearEvent( $event );
        }
        last;
      };
      $_ == cmClose and do {
        no warnings 'uninitialized';
        if ( $self->{flags} & wfClose
          && ( !$event->{message}{infoPtr}
            || 0+$event->{message}{infoPtr} == 0+$self
          ) 
        ) {
          $self->clearEvent( $event );
          if ( !( $self->{state} & sfModal ) ) {
            $self->close();
          }
          else {
            $event->{what} = evCommand;
            $event->{message}{command} = cmCancel;
            $self->putEvent( $event );
            $self->clearEvent( $event );
          }
        } #/ if ( $self->{flags} & ...)
        last;
      };
      $_ == cmZoom and do {
        no warnings 'uninitialized';
        if ( $self->{flags} & wfZoom
          && ( !$event->{message}{infoPtr} 
            || 0+$event->{message}{infoPtr} == 0+$self
          )
        ) {
          $self->zoom();
          $self->clearEvent( $event );
        }
        last;
      };
    }
  }
  elsif ( $event->{what} == evKeyDown ) {
    SWITCH: for ( $event->{keyDown}{keyCode} ) {
      $_ == kbTab and do {
        $self->focusNext( 0 );
        $self->clearEvent( $event );
        last;
      };
      $_ == kbShiftTab and do {
        $self->focusNext( 1 );
        $self->clearEvent( $event );
        last;
      };
    }
  } #/ elsif ( $event->{what} ==...)
  elsif ( $event->{what} == evBroadcast
    && $event->{message}{command} == cmSelectWindowNum
    && $event->{message}{infoInt} == $self->{number}
    && ( $self->{options} & ofSelectable )
  ) {
    $self->select();
    $self->clearEvent( $event );
  }
  return;
} #/ sub handleEvent

sub initFrame {    # $frame ($r)
  my ( $class, $r ) = @_;
  assert ( $class );
  assert ( ref $r );
  return TFrame->new( bounds => $r );
}

sub setState {    # void ($aState, $enable)
  my ( $self, $aState, $enable ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aState );
  assert ( !defined $enable or !ref $enable );
  my $windowCommands = TCommandSet->new();

  $self->SUPER::setState( $aState, $enable );
  if ( $aState & sfSelected ) {
    $self->setState( sfActive, $enable );
    if ( $self->{frame} ) {
      $self->{frame}->setState( sfActive, $enable );
    }
    $windowCommands->add( cmNext );
    $windowCommands->add( cmPrev );
    if ( $self->{flags} & ( wfGrow | wfMove ) ) {
      $windowCommands->add( cmResize );
    }
    if ( $self->{flags} & wfClose ) {
      $windowCommands->add( cmClose );
    }
    if ( $self->{flags} & wfZoom ) {
      $windowCommands->add( cmZoom );
    }
    if ( $enable ) {
      $self->enableCommands( $windowCommands );
    }
    else {
      $self->disableCommands( $windowCommands );
    }
  } #/ if ( $aState & sfSelected)
  return;
} #/ sub setState

sub sizeLimits {    # void ($min, $max)
  my ( $self, $min, $max ) = @_;
  assert ( blessed $self );
  assert ( blessed $min );
  assert ( blessed $max );
  $self->SUPER::sizeLimits( $min, $max );
  @$min{qw(x y)} = @$minWinSize{qw(x y)};
  return;
}

sub standardScrollBar {    # $scrollBar ($aOptions)
  my ( $self, $aOptions ) = @_;
  my $r = $self->getExtent();
  if ( $aOptions & sbVertical ) {
    $r = TRect->new(
      ax => $r->{b}{x} - 1, ay => $r->{a}{y} + 1,
      bx => $r->{b}{x},     by => $r->{b}{y} - 1,
    );
  }
  else {
    $r = TRect->new(
      ax => $r->{a}{x} + 2, ay => $r->{b}{y} - 1, 
      bx => $r->{b}{x} - 2, by => $r->{b}{y},
    );
  }

  my $s = TScrollBar->new( bounds => $r );
  $self->insert( $s );
  if ( $aOptions & sbHandleKeyboard ) {
    $s->{options} |= ofPostProcess;
  }
  return $s;
} #/ sub standardScrollBar

sub zoom {    # void ()
  my $self = shift;
  assert ( blessed $self );
  my ( $minSize, $maxSize ) = ( TPoint->new(), TPoint->new() );
  $self->sizeLimits( $minSize, $maxSize );
  if ( $self->{size} != $maxSize ) {
    $self->{zoomRect} = $self->getBounds();
    my $r = TRect->new( 
      ax => 0, ay => 0, bx => $maxSize->{x}, by => $maxSize->{y}
    );
    $self->locate( $r );
  }
  else {
    $self->locate( $self->{zoomRect} );
  }
  return;
} #/ sub zoom

sub shutDown {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->{frame} = undef;
  $self->SUPER::shutDown();
  return;
}

1
