package TV::App::Program;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TProgram
  new_TProgram
);
our @EXPORT_OK = qw(
  $application
  $deskTop
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
  weaken
);

use TV::App::Const qw( 
  :apXXXX
  :cpXXXX
);
use TV::App::DeskTop;
use TV::App::ProgInit;
use TV::Drivers::Const qw( 
  :evXXXX
  :kbXXXX
  :smXXXX
);
use TV::Drivers::Event;
use TV::Drivers::EventQueue;
use TV::Drivers::Screen;
use TV::Drivers::Util qw( getAltChar );
use TV::Menus::MenuBar;
use TV::Menus::StatusDef;
use TV::Menus::StatusItem;
use TV::Menus::StatusLine;
use TV::Memory::Util qw( lowMemory );
use TV::Objects::Point;
use TV::Objects::Rect;
use TV::Views::Const qw( 
  :cmXXXX
  :sfXXXX
);
use TV::Views::Palette;
use TV::Views::Group;
use TV::Views::Util qw( message );
use TV::Views::View;
use TV::toolkit;

sub TProgram() { __PACKAGE__ }
sub new_TProgram { __PACKAGE__->from(@_) }

extends ( TGroup, TProgInit );

# declare global variables
our $exitText = "~Alt-X~ Exit";
our $application;
our $statusLine;
our $menuBar;
our $deskTop;
our $appPalette = 0;
our $pending = TEvent->new();

# import global variables
use vars qw(
  $mouse
  $screenBuffer
  $screenHeight
  $screenMode
  $screenWidth
  $commandSetChanged
  $showMarkers
  $shadowSize
);
{
  no strict 'refs';
  *mouse             = \${ TEventQueue . '::mouse' };
  *screenBuffer      = \${ TScreen . '::screenBuffer' };
  *screenHeight      = \${ TScreen . '::screenHeight' };
  *screenMode        = \${ TScreen . '::screenMode' };
  *screenWidth       = \${ TScreen . '::screenWidth' };
  *commandSetChanged = \${ TView . '::commandSetChanged' };
  *showMarkers       = \${ TView . '::showMarkers' };
  *shadowSize        = \${ TView . '::shadowSize' };
}

sub BUILDARGS {    # \%args ()
  my $class = shift;
  assert( $class and !ref $class );
  assert( @_ == 0 );
  my $args1 = TGroup->BUILDARGS(
    bounds => TRect->new(
      ax => 0,
      ay => 0,
      bx => $screenWidth,
      by => $screenHeight,
    )
  );
  my $args2 = TProgInit->BUILDARGS(
    cStatusLine => $class->can( 'initStatusLine' ),
    cMenuBar    => $class->can( 'initMenuBar' ),
    cDeskTop    => $class->can( 'initDeskTop' ),
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert ( blessed $self );
  $application = $self;
  $self->initScreen();
  $self->{state}   = sfVisible | sfSelected | sfFocused | sfModal | sfExposed;
  $self->{options} = 0;
  $self->{buffer}  = $screenBuffer;

  if ( $self->{createDeskTop}
    && ( $deskTop = $self->createDeskTop( $self->getExtent() ) ) 
  ) {
    $self->insert( $deskTop );
  }
  if ( $self->{createStatusLine}
    && ( $statusLine = $self->createStatusLine( $self->getExtent() ) ) 
  ) {
    $self->insert( $statusLine );
  }
  if ( $self->{createMenuBar}
    && ( $menuBar = $self->createMenuBar( $self->getExtent() ) ) 
  ) {
    $self->insert( $menuBar );
  }
  return;
}

sub from {    # $obj ()
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 0 );
  return $class->new();
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( blessed $self );
  $application = undef;
  return;
}

sub canMoveFocus {    # $bool ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  return $deskTop->valid( cmReleasedFocus );
}

sub executeDialog {    # $int ($pD, |\@data)
  my ( $self, undef, $data ) = @_;
  alias: for my $pD ( $_[1] ) {
  assert ( @_ >= 2 && @_ <= 3 );
  assert ( blessed $self );
  assert ( blessed $pD );
  my $c = cmCancel;

  if ( $self->validView( $pD ) ) {
    $pD->setData( $data ) 
      if $data;
    $c = $deskTop->execView( $pD );
    $pD->getData( $data ) 
      if ( $c != cmCancel && $data );
    $self->destroy( $pD );
  }

  return $c;
  } #/ alias
} #/ sub executeDialog

my $hasMouse = sub {    # $bool ($p, $s)
  my ( $p, $s ) = @_;
  return ( $p->{state} & sfVisible ) && $p->mouseInView( $s->{mouse}{where} );
};

sub getEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );
  if ( $pending->{what} != evNothing ) {
    $event->assign( $pending );
    $pending->{what} = evNothing;
  }
  else {
    $event->getMouseEvent();
    if ( $event->{what} == evNothing ) {
      $event->getKeyEvent();
      $self->idle() 
        if $event->{what} == evNothing;
    }
  }

  if ( $statusLine ) {
    no warnings 'uninitialized';
    if (
      ( $event->{what} & evKeyDown )
      || ( ( $event->{what} & evMouseDown )
        && $self->firstThat( $hasMouse, $event ) == $statusLine )
    ) {
      $statusLine->handleEvent( $event );
    }
  } #/ if ( $self->{statusLine...})
  return;
} #/ sub getEvent

my ( $color, $blackwhite, $monochrome, @palettes );
sub getPalette {    # $palette ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $color ||= TPalette->new(
    data => cpAppColor, 
    size => length( cpAppColor ) 
  );
  $blackwhite ||= TPalette->new( 
    data => cpAppBlackWhite, 
    size => length( cpAppBlackWhite ) 
  );
  $monochrome ||= TPalette->new( 
    data => cpAppMonochrome, 
    size => length( cpAppMonochrome ) 
  );
  @palettes = ( $color, $blackwhite, $monochrome ) unless @palettes;
  return $palettes[$appPalette]->clone();
} #/ sub getPalette

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );
  if ( $event->{what} == evKeyDown ) {
    my $c = getAltChar( $event->{keyDown}{keyCode} );
    if ( $c ge '1' && $c le '9' ) {
      if ( $self->canMoveFocus() ) {    # <--- Check valid first.
        if ( message( $deskTop, evBroadcast, cmSelectWindowNum, 
              chr( ord( $c ) - ord( '0' ) ) ) 
        ) {
          $self->clearEvent( $event );
        }
      } #/ if ( $self->canMoveFocus...)
      else {
        $self->clearEvent( $event );
      }
    } #/ if ( $c ge '1' && $c le...)
  } #/ if ( $event->{what} eq...)

  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evCommand && $event->{message}{command} == cmQuit ) {
    $self->endModal( cmQuit );
    $self->clearEvent( $event );
  }
  return;
} #/ sub handleEvent

sub idle {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $statusLine->update() 
    if $statusLine;

  if ( $commandSetChanged ) {
    message( $self, evBroadcast, cmCommandSetChanged, 0 );
    $commandSetChanged = !!0;
  }
  return;
}

sub initScreen { # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  if ( ( $screenMode & 0x00FF ) != smMono ) {
    if ( $screenMode & smFont8x8 ) {
      $shadowSize->{x} = 1;
    }
    else {
      $shadowSize->{x} = 2;
    }
    $shadowSize->{y} = 1;
    $showMarkers = !!0;
    if ( ( $screenMode & 0x00FF ) == smBW80 ) {
      $appPalette = apBlackWhite;
    }
    else {
      $appPalette = apColor;
    }
  } #/ if ( ( $screenMode & 0x00FF...))
  else {
    $shadowSize->{x} = 0;
    $shadowSize->{y} = 0;
    $showMarkers     = !!1;
    $appPalette      = apMonochrome;
  }
  return;
} #/ sub initScreen

sub outOfMemory {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  # Handle out of memory
  return;
}

sub putEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );
  $pending = $event->clone();
  return;
}

sub run {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $self->execute();
  return;
}

sub insertWindow {    # $window|undef ($pWin|undef)
  my ( $self, undef ) = @_;
  alias: for my $pWin ( $_[1] ) {
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $pWin );
  if ( $self->validView( $pWin ) ) {
    if ( $self->canMoveFocus() ) {
      $deskTop->insert( $pWin );
      return $pWin;
    }
    else {
      $self->destroy( $pWin );
    }
  }
  return undef;
  } #/ alias
} #/ sub insertWindow

sub setScreenMode { # void ($mode)
  my ( $self, $mode ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $mode );
  my $r;

  $mouse->hide();
  TScreen->setVideoMode( $mode );
  $self->initScreen();
  $self->{buffer} = $screenBuffer;
  $r = TRect->new( ax => 0, bx => 0, ay => $screenWidth, by => $screenHeight );
  $self->changeBounds( $r );
  $self->setState( sfExposed, 0 );
  $self->setState( sfExposed, 1 );
  $self->redraw();
  $mouse->show();
  return;
} #/ sub setScreenMode

sub shutDown {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  weaken $application 
    if $application 
    && !isweak $application;
  $statusLine = undef;
  $menuBar    = undef;
  $deskTop    = undef;
  $self->SUPER::shutDown();
  # TVMemMgr->clearSafetyPool();
  return;
} #/ sub shutDown

sub suspend {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  return;
}

sub resume {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  return;
}

sub initStatusLine {    # $statusLine ($r)
  my ( $class, $r ) = @_;
  assert ( @_ == 2 );
  assert ( $class and !ref $class );
  assert ( ref $r );
  $r->{a}{y} = $r->{b}{y} - 1;
  return TStatusLine->from( $r,
    TStatusDef->from( 0, 0xFFFF ) +
      TStatusItem->from( $exitText, kbAltX,   cmQuit ) +
      TStatusItem->from( '',        kbF10,    cmMenu ) +
      TStatusItem->from( '',        kbAltF3,  cmClose ) +
      TStatusItem->from( '',        kbF5,     cmZoom ) +
      TStatusItem->from( '',        kbCtrlF5, cmResize )
  );
} #/ sub initStatusLine

sub initMenuBar {    # $menuBar ($r)
  my ( $class, $r ) = @_;
  assert ( @_ == 2 );
  assert ( $class and !ref $class );
  assert ( ref $r );
  $r->{b}{y} = $r->{a}{y} + 1;
  return TMenuBar->new( bounds => $r, menu => undef );
}

sub initDeskTop {    # $deskTop ($r)
  my ( $class, $r ) = @_;
  assert ( @_ == 2 );
  assert ( $class and !ref $class );
  assert ( ref $r );
  $r->{a}{y}++;
  $r->{b}{y}--;
  return TDeskTop->new( bounds => $r );
}

sub validView {    # $view|undef ($view)
  my ( $self, undef ) = @_;
  alias: for my $p ( $_[1] ) {
  assert ( @_ == 2 );
  assert ( blessed $self );
  return undef unless $p;
  if ( lowMemory() ) {
    $self->destroy( $p );
    $self->outOfMemory();
    return undef;
  }
  unless ( $p->valid( cmValid ) ) {
    $self->destroy( $p );
    return undef;
  }
  return $p;
  } #/ alias: for my $p
} #/ sub validView

1
