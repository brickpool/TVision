package TV::Views::Frame;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TFrame
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use List::Util qw( min max );
use Scalar::Util qw(
  blessed
  looks_like_number
  weaken
);

use TV::Drivers::Const qw(
  :evXXXX
  meDoubleClick
);
use TV::Objects::DrawBuffer;
use TV::Views::Const qw(
  cmClose cmZoom
  cpFrame
  dmDragGrow dmDragMove
  gfGrowHiX gfGrowHiY
  sfActive sfDragging
  :wfXXXX
  wnNoNumber
);
use TV::Views::Palette;
use TV::Views::View;
use TV::toolkit;

sub TFrame() { __PACKAGE__ }
sub name() { 'TFrame' }

extends TView;

# declare global variables
our $initFrame =
  "\x06\x0A\x0C\x05\x00\x05\x03\x0A\x09\x16\x1A\x1C\x15\x00\x15\x13\x1A\x19";

our $frameChars =
  "   └ │┌├ ┘─┴┐┤┬┼   ╚ ║╔╟ ╝═╧╗╢╤ ";    # for UnitedStates code page

our $closeIcon  = "[~\xFE~]";
our $zoomIcon   = "[~\x18~]";
our $unZoomIcon = "[~\x12~]";
our $dragIcon   = "~─┘~";

# import frameLine
require TV::Views::Frame::Line;

sub BUILD {    # void (| \%args)
  my $self = shift;
  assert ( blessed $self );
  $self->{growMode} = gfGrowHiX | gfGrowHiY;
  $self->{eventMask} |= evBroadcast | evMouseUp;
  return;
}

sub draw {    # void ()
  my $self = shift;
  assert ( blessed $self );
  my ( $cFrame, $cTitle, $f, $i, $l, $width );
  my $b = TDrawBuffer->new();

  if ( ( $self->{state} & sfDragging ) != 0 ) {
    $cFrame = 0x0505;
    $cTitle = 0x0005;
    $f      = 0;
  }
  elsif ( ( $self->{state} & sfActive ) == 0 ) {
    $cFrame = 0x0101;
    $cTitle = 0x0002;
    $f      = 0;
  }
  else {
    $cFrame = 0x0503;
    $cTitle = 0x0004;
    $f      = 9;
  }

  $cFrame = $self->getColor( $cFrame );
  $cTitle = $self->getColor( $cTitle );

  $width = $self->{size}{x};
  $l     = $width - 10;

  $l -= 6 if $self->owner->{flags} & ( wfClose | wfZoom );
  $self->frameLine( $b, 0, $f, $cFrame );
  if ( $self->owner->{number} != wnNoNumber
    && $self->owner->{number} < 10
  ) {
    $l -= 4;
    $i = 3;
    $i += 4 if $self->owner->{flags} & wfZoom;
    $b->putChar( $width - $i, chr( $self->owner->{number} + ord( '0' ) ) );
  }

  if ( $self->owner ) {
    my $title = $self->owner->getTitle( $l );
    if ( $title ) {
      $l = min( length( $title ), $width - 10 );
      $l = max( $l, 0 );
      $i = ( $width - $l ) >> 1;
      $b->putChar( $i - 1, ' ' );
      $b->moveBuf( $i, [ split // => $title ], $cTitle, $l );
      $b->putChar( $i + $l, ' ' );
    }
  } #/ if ( $self->owner )

  if ( $self->{state} & sfActive ) {
    if ( $self->owner->{flags} & wfClose ) {
      $b->moveCStr( 2, $self->{closeIcon}, $cFrame );
    }
    if ( $self->owner->{flags} & wfZoom ) {
      my ( $minSize, $maxSize );
      $self->owner->sizeLimits( $minSize, $maxSize );
      if ( $self->owner->{size} == $maxSize ) {
        $b->moveCStr( $width - 5, $unZoomIcon, $cFrame );
      }
      else {
        $b->moveCStr( $width - 5, $zoomIcon, $cFrame );
      }
    } #/ if ( ( $self->owner->...))
  } #/ if ( ( $self->{state} ...))

  $self->writeLine( 0, 0, $self->{size}{x}, 1, $b );
  for ( $i = 1 ; $i <= $self->{size}{y} - 2 ; $i++ ) {
    $self->frameLine( $b, $i, $f + 3, $cFrame );
    $self->writeLine( 0, $i, $self->{size}{x}, 1, $b );
  }
  $self->frameLine( $b, $self->{size}{y} - 1, $f + 6, $cFrame );
  if ( $self->{state} & sfActive ) {
    if ( $self->owner->{flags} & wfGrow ) {
      $b->moveCStr( $width - 2, $dragIcon, $cFrame );
    }
  }
  $self->writeLine( 0, $self->{size}{y} - 1, $self->{size}{x}, 1, $b );
  return;
} #/ sub draw

my $palette;
sub getPalette {    # $palette ()
  my $self = shift;
  assert ( blessed $self );
  $palette ||= TPalette->new(
    data => cpFrame, 
    size => length( cpFrame ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evMouseDown ) {
    my $mouse = $self->makeLocal( $event->{mouse}{where} );
    if ( $mouse->{y} == 0 ) {
      if ( ( $self->owner->{flags} & wfClose ) != 0
        && ( $self->{state} & sfActive )
        && $mouse->{x} >= 2
        && $mouse->{x} <= 4 )
      {
        while ( $self->mouseEvent( $event, evMouse ) ) { }
        $mouse = $self->makeLocal( $event->{mouse}{where} );
        if ( $mouse->{y} == 0 && $mouse->{x} >= 2 && $mouse->{x} <= 4 ) {
          $event->{what}             = evCommand;
          $event->{message}{command} = cmClose;
          $event->{message}{infoPtr} = $self->owner;
          $self->putEvent( $event );
          $self->clearEvent( $event );
        }
      } #/ if ( ( $self->owner->...))
      elsif (
        ( $self->owner->{flags} & wfZoom ) != 0
        && ( $self->{state} & sfActive )
        && (
          (
            $mouse->{x} >= $self->{size}{x} - 5 && $mouse->{x} <= $self->{size}{x} - 3
          )
          || ( $event->{mouse}{eventFlags} & meDoubleClick )
        )
        )
      {
        $event->{what}             = evCommand;
        $event->{message}{command} = cmZoom;
        weaken( $event->{message}{infoPtr} = $self->owner );
        $self->putEvent( $event );
        $self->clearEvent( $event );
      } #/ elsif ( ( $self->owner->...))
      elsif ( $self->owner->{flags} & wfMove ) {
        $self->dragWindow( $event, dmDragMove );
      }
    } #/ if ( $mouse->{y} == 0 )
    elsif ( $mouse->{x} >= $self->{size}{x} - 2
      && $mouse->{y} >= $self->{size}{y} - 1
      && ( $self->{state} & sfActive ) )
    {
      if ( ( $self->owner->{flags} & wfGrow ) != 0 ) {
        $self->dragWindow( $event, dmDragGrow );
      }
    }
  } #/ if ( $event->{what} ==...)
  return;
} #/ sub handleEvent

sub setState {    # void ($aState, $enable)
  my ( $self, $aState, $enable ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aState );
  assert ( !defined $enable or !ref $enable );
  $self->SUPER::setState( $aState, $enable );
  if ( ( $aState & ( sfActive | sfDragging ) ) != 0 ) {
    $self->drawView();
  }
  return;
}

sub dragWindow {    # void ($event, $mode)
  my ( $self, $event, $mode ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  assert ( looks_like_number $mode );
  my $limits = $self->owner->owner->getExtent();
  my ( $min, $max );
  $self->owner->sizeLimits( $min, $max );
  $self->owner->dragView( 
    $event, $self->owner->{dragMode} | $mode, $limits, $min, $max
  );
  $self->clearEvent( $event );
  return;
} #/ sub dragWindow

1;
