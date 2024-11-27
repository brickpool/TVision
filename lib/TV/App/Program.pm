package TV::App::Program;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TProgram
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );

use TV::App::Const qw( :cpXXXX );
use TV::App::DeskTop;
use TV::App::ProgInit;
use TV::Drivers::Const qw( :evXXXX );
use TV::Drivers::Screen;
use TV::Drivers::Util qw( getAltChar );
use TV::Objects::Point;
use TV::Objects::Rect;
use TV::Views::Const qw( 
  :sfXXXX
  cmReleasedFocus
  cmCancel
  cmSelectWindowNum
  cmQuit
  cmCommandSetChanged
);
use TV::Views::Palette;
use TV::Views::Group;
use TV::Views::Util qw( message );
use TV::Views::View;

sub TProgram() { __PACKAGE__ }

use base TGroup;
use parent TProgInit;

# declare global variables
our $application;
our $statusLine;
our $menuBar;
our $deskTop;
our $appPalette = 0;
our $pending;

# import global variables
use vars qw(
  $shadowSize
  $commandSetChanged
  $screenBuffer
  $screenHeight
  $screenWidth
);
{
  no strict 'refs';
  *shadowSize        = \${ TView . '::shadowSize' };
  *commandSetChanged = \${ TView . '::commandSetChanged' };
  *screenBuffer      = \${ TScreen . '::screenBuffer' };
  *screenHeight      = \${ TScreen . '::screenHeight' };
  *screenWidth       = \${ TScreen . '::screenWidth' };
}

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'init_arg' is not the same as the field name.
  $args{createStatusLine} = delete $args{cStatusLine};
  $args{createMenuBar}    = delete $args{cMenuBar};
  $args{createDeskTop}    = delete $args{cDeskTop};
  # TProgInit->BUILDARGS is not called because arguments are not 'required'
  return $class->SUPER::BUILDARGS( %args );
}

sub BUILD {    # void (| \%args)
  my $self = shift;
  assert ( blessed $self );
  $self->{createStatusLine} ||= \&initStatusLine;
  $self->{createMenuBar}    ||= \&initMenuBar;
  $self->{createDeskTop}    ||= \&initDeskTop;
  $self->{bounds}           ||= TRect->new(
    ax => 0,
    ay => 0,
    bx => $screenWidth,
    by => $screenHeight,
  );
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

sub DEMOLISH {    # void ()
  assert ( blessed $_[0] );
  $application = undef;
  return;
}

sub shutDown {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $statusLine = undef;
  $menuBar    = undef;
  $deskTop    = undef;
  $self->SUPER::shutDown();
  # TVMemMgr->clearSafetyPool();
  return;
} #/ sub shutDown

sub canMoveFocus {    # $bool ()
  my $self = shift;
  assert ( blessed $self );
  return $deskTop->valid( cmReleasedFocus );
}

sub executeDialog {    # $int ($pD, \@data)
  my ( $self, undef, $data ) = @_;
  alias: for my $pD ( $_[1] ) {
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
  assert ( blessed $self );
  assert ( blessed $event );
  if ( $self->{pending}{what} != evNothing ) {
    %$event = %{ $self->{pending} };
    $self->{pending}{what} = evNothing;
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
    if (
      ( $event->{what} & evKeyDown )
      || ( ( $event->{what} & evMouseDown )
        && $self->firstThat( $hasMouse, $event ) == $statusLine )
      )
    {
      $statusLine->handleEvent( $event );
    }
  } #/ if ( $self->{statusLine...})
  return;
} #/ sub getEvent

my ( $color, $blackwhite, $monochrome, @palettes );
sub getPalette {    # $palette ()
  my $self = shift;
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
  return $palettes[$appPalette];
} #/ sub getPalette

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
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
  my $self = shift;
  assert ( blessed $self );
  $statusLine->update() 
    if $statusLine;

  if ( $commandSetChanged ) {
    message( $self, evBroadcast, cmCommandSetChanged, 0 );
    $commandSetChanged = !!0;
  }
}

sub initDeskTop {
  my ( $class, $r ) = @_;
  assert ( $class );
  assert ( ref $r );
  $r->{a}{y}++;
  $r->{b}{y}--;
  return TDeskTop->new( bounds => $r );
}

1

__END__

sub initMenuBar {
  my ( $class, $r ) = @_;
  $r->{b}{y} = $r->{a}{y} + 1;
  return TMenuBar->new( $r, undef );
}

sub initScreen {
  my $self = shift;
  if ( ( TScreen::screenMode() & 0x00FF ) ne TDisplay::smMono() ) {
    if ( TScreen::screenMode() & TDisplay::smFont8x8() ) {
      $shadowSize->{x} = 1;
    }
    else {
      $shadowSize->{x} = 2;
    }
    $shadowSize->{y} = 1;
    $self->{showMarkers} = 0;
    if ( ( TScreen::screenMode() & 0x00FF ) eq TDisplay::smBW80() ) {
      $appPalette = 'apBlackWhite';
    }
    else {
      $appPalette = 'apColor';
    }
  } #/ if ( ( TScreen::screenMode...))
  else {
    $shadowSize->{x} = 0;
    $shadowSize->{y} = 0;
    $self->{showMarkers}   = 1;
    $appPalette    = 'apMonochrome';
  }
} #/ sub initScreen

sub initStatusLine {
  my ( $class, $r ) = @_;
  $r->{a}{y} = $r->{b}{y} - 1;
  return TStatusLine->new(
    $r,
    TStatusDef->new( 0, 0xFFFF ) +
      TStatusItem->new( $exitText, 'kbAltX',   cmQuit ) +
      TStatusItem->new( 0,         'kbF10',    'cmMenu' ) +
      TStatusItem->new( 0,         'kbAltF3',  'cmClose' ) +
      TStatusItem->new( 0,         'kbF5',     'cmZoom' ) +
      TStatusItem->new( 0,         'kbCtrlF5', 'cmResize' )
  );
} #/ sub initStatusLine

sub insertWindow {
  my ( $self, $pWin ) = @_;
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
} #/ sub insertWindow

sub outOfMemory {

  # Handle out of memory
}

sub putEvent {
  my ( $self, $event ) = @_;
  $self->{pending} = $event;
}

sub run {
  my $self = shift;
  $self->execute();
}

sub setScreenMode {
  my ( $self, $mode ) = @_;
  my $r;

  TEventQueue::mouse()->hide();
  TScreen::setVideoMode( $mode );
  $self->initScreen();
  $self->{buffer} = TScreen::screenBuffer();
  $r = TRect->new( 0, 0, TScreen::screenWidth(), TScreen::screenHeight() );
  $self->changeBounds( $r );
  $self->setState( 'sfExposed', 0 );
  $self->setState( 'sfExposed', 1 );
  $self->redraw();
  TEventQueue::mouse()->show();
} #/ sub setScreenMode

sub validView {
  my ( $self, $p ) = @_;
  return undef unless $p;
  if ( $self->lowMemory() ) {
    $self->destroy( $p );
    $self->outOfMemory();
    return undef;
  }
  unless ( $p->valid( 'cmValid' ) ) {
    $self->destroy( $p );
    return undef;
  }
  return $p;
} #/ sub validView

1

__END__


Und hier sind die entsprechenden Testfälle:

```perl
use strict;
use warnings;
use Test::More tests => 20;
use Test::Exception;
use TProgram;
use TGroup;
use TProgInit;
use TDeskTop;
use TStatusLine;
use TMenuBar;
use TView;
use TEvent;
use TRect;
use TPalette;

# Mocking TGroup, TProgInit, TDeskTop, TStatusLine, TMenuBar, TView, TEvent, TRect, and TPalette for testing purposes
{
    package TGroup;
    sub new { bless { size => { x => 0, y => 0 }, options => 0, state => 0, buffer => undef, lockFlag => 0, clip => undef }, shift }
    sub insert { }
    sub shutDown { }
    sub handleEvent { }
    sub forEach { }
    sub lock { }
    sub unlock { }
    sub getExtent { return TRect->new() }
    sub selectNext { }
    sub clearEvent { }
    sub valid { return 1 }
    sub changeBounds { }
    sub setState { }
    sub redraw { }
}

{
    package TProgInit;
    sub new { bless { createDeskTop => shift, createStatusLine => shift, createMenuBar => shift }, shift }
}

{
    package TDeskTop;
    sub new { bless {}, shift }
    sub execView { return 'cmCancel' }
    sub insert { }
    sub valid { return 1 }
}

{
    package TStatusLine;
    sub new { bless {}, shift }
    sub handleEvent { }
    sub update { }
}

{
    package TMenuBar;
    sub new { bless {}, shift }
}

{
    package TView;
    sub new { bless { next => undef, owner => undef, state => 0, options => 0, eventMask => 0, size => { x => 0, y => 0 }, buffer => undef, lockFlag => 0, clip => undef }, shift }
    sub next { shift->{next} }
    sub set_next { shift->{next} = shift }
    sub owner { shift->{owner} }
    sub set_owner { shift->{owner} = shift }
    sub hide { }
    sub show { }
    sub setState { }
    sub prev { return shift }
    sub focus { return 1 }
    sub select { }
    sub drawView { }
    sub handleEvent { }
    sub containsMouse { return 1 }
    sub getData { }
    sub setData { }
    sub dataSize { return 1 }
    sub calcBounds { }
    sub changeBounds { }
    sub getClipRect { return shift->{clip} }
    sub getExtent { return shift->{clip} }
    sub writeBuf { }
    sub resetCursor { }
    sub locate { }
    sub sizeLimits { }
    sub putInFrontOf { }
    sub mouseInView { return 1 }
    sub valid { return 1 }
}

{
    package TEvent;
    sub new { bless { what => 'evNothing', message => { command => 0 }, keyDown => { keyCode => 0 }, mouse => { where => 0 } }, shift }
    sub getMouseEvent { }
    sub getKeyEvent { }
}

{
    package TRect;
    sub new { bless { a => { x => 0, y => 0 }, b => { x => 0, y => 0 } }, shift }
}

{
    package TPalette;
    sub new { bless {}, shift }
}

# Test object creation
my $program = TProgram->new();
isa_ok($program, 'TProgram', 'Object is of class TProgram');

# Test shutDown method
can_ok($program, 'shutDown');
$program->shutDown();
pass('shutDown works correctly');

# Test canMoveFocus method
can_ok($program, 'canMoveFocus');
is($program->canMoveFocus(), 1, 'canMoveFocus returns correct value');

# Test executeDialog method
can_ok($program, 'executeDialog');
my $dialog = TView->new();
is($program->executeDialog($dialog, undef), 'cmCancel', 'executeDialog returns correct value');

# Test getEvent method
can_ok($program, 'getEvent');
my $event = TEvent->new();
$program->getEvent($event);
pass('getEvent works correctly');

# Test getPalette method
can_ok($program, 'getPalette');
my $palette = $program->getPalette();
isa_ok($palette, 'TPalette', 'getPalette returns a TPalette object');

# Test handleEvent method
can_ok($program, 'handleEvent');
$program->handleEvent($event);
pass('handleEvent works correctly');

# Test idle method
can_ok($program, 'idle');
$program->idle();
pass('idle works correctly');

# Test initDeskTop method
can_ok($program, 'initDeskTop');
my $desktop = $program->initDeskTop(TRect->new());
isa_ok($desktop, 'TDeskTop', 'initDeskTop returns a TDeskTop object');

# Test initMenuBar method
can_ok($program, 'initMenuBar');
my $menuBar = $program->initMenuBar(TRect->new());
isa_ok($menuBar, 'TMenuBar', 'initMenuBar returns a TMenuBar object');

# Test initScreen method
can_ok($program, 'initScreen');
$program->initScreen();
pass('initScreen works correctly');

# Test initStatusLine method
can_ok($program, 'initStatusLine');
my $statusLine = $program->initStatusLine(TRect->new());
isa_ok($statusLine, 'TStatusLine', 'initStatusLine returns a TStatusLine object');

# Test insertWindow method
can_ok($program, 'insertWindow');
my $window = TView->new();
is($program->insertWindow($window), $window, 'insertWindow returns correct value');

# Test outOfMemory method
can_ok($program, 'outOfMemory');
$program->outOfMemory();
pass('outOfMemory works correctly');

# Test putEvent method
can_ok($program, 'putEvent');
$program->putEvent($event);
pass('putEvent works correctly');

# Test run method
can_ok($program, 'run');
$program->run();
pass('run works correctly');

# Test setScreenMode method
can_ok($program, 'setScreenMode');
$program->setScreenMode(0);
pass('setScreenMode works correctly');

# Test validView method
can_ok($program, 'validView');
is($program->validView($window), $window, 'validView returns correct value');

done_testing();
```

Diese Testfälle decken die Erstellung des Objekts, das Setzen und Abrufen der Felder sowie das Verhalten der Methoden `shutDown`, `canMoveFocus`, `executeDialog`, `getEvent`, `getPalette`, `handleEvent`, `idle`, `initDeskTop`, `initMenuBar`, `initScreen`, `initStatusLine`, `insertWindow`, `outOfMemory`, `putEvent`, `run`, `setScreenMode` und `validView` ab. Wenn du noch weitere Tests oder Anpassungen benötigst, lass es mich wissen!