package TV::Drivers::Screen;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TScreen
);

use Data::Alias;
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( looks_like_number );

use TV::Drivers::Const qw( :smXXXX );
use TV::Drivers::Display;
use TV::Drivers::HardwareInfo;
use TV::Drivers::Mouse;

sub TScreen() { __PACKAGE__ }

use parent TDisplay;

our $startupMode    = 0xffff;
our $startupCursor  = 0;
our $screenMode     = 0;
our $screenWidth    = 0;
our $screenHeight   = 0;
our $hiResScreen    = !!0;
our $checkSnow      = !!1;
our $screenBuffer   = [];
our $cursorLines    = 0;
our $clearOnSuspend = !!1;
{
  no warnings 'once';
  alias TScreen->{startupMode}    = $startupMode;
  alias TScreen->{startupCursor}  = $startupCursor;
  alias TScreen->{screenMode}     = $screenMode;
  alias TScreen->{screenWidth}    = $screenWidth;
  alias TScreen->{screenHeight}   = $screenHeight;
  alias TScreen->{hiResScreen}    = $hiResScreen;
  alias TScreen->{checkSnow}      = $checkSnow;
  alias TScreen->{screenBuffer}   = $screenBuffer;
  alias TScreen->{cursorLines}    = $cursorLines;
  alias TScreen->{clearOnSuspend} = $clearOnSuspend;
}

INIT: {
  $startupMode   = TScreen->getCrtMode();
  $startupCursor = TScreen->getCursorType();
  $screenBuffer  = THardwareInfo->allocateScreenBuffer()
    if THardwareInfo->can('allocateScreenBuffer');
  TScreen->setCrtData();
}

sub END {
  TScreen->suspend();
  THardwareInfo->freeScreenBuffer( $screenBuffer ) 
    if THardwareInfo->can('freeScreenBuffer');
}

sub resume {    # void ($class)
  my $class = shift;
  assert ( $class and !ref $class );
  $startupMode   = $class->getCrtMode();
  $startupCursor = $class->getCursorType();
  if ( $screenMode != $startupMode ) {
    $class->setCrtMode( $screenMode );
  }
  $class->setCrtData();
  return;
} #/ sub resume

sub suspend {    # void ($class)
  my $class = shift;
  assert ( $class and !ref $class );
  if ( $startupMode != $class->getCrtMode() ) {
    $class->setCrtMode( $startupMode );
  }
  if ( $clearOnSuspend ) {
    $class->clearScreen();
  }
  $class->setCursorType( $startupCursor );
  return;
} #/ sub suspend

sub fixCrtMode {    # $mode ($class, $mode)
  my ( $class, $mode ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $mode );
  if ( THardwareInfo->getPlatform() eq 'Windows' ) {
    $mode = ( $mode & SM_FONT_8X8 ) ? SM_CO80 | SM_FONT_8X8 : SM_CO80;
    return $mode;
  }
  if ( ( $mode & 0xff ) == SM_MONO ) {    # Strip SM_FONT_8X8 if necessary.
    return SM_MONO;
  }
  return $mode;
} #/ sub fixCrtMode

sub setCrtData {    # void ($class)
  my $class = shift;
  assert ( $class and !ref $class );
  $screenMode   = $class->getCrtMode();
  $screenWidth  = $class->getCols();
  $screenHeight = $class->getRows();
  $hiResScreen  = $screenHeight > 25;

  $cursorLines = $class->getCursorType();
  $class->setCursorType( 0 );
  return;
} #/ sub setCrtData

sub clearScreen {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  TDisplay->clearScreen( $screenWidth, $screenHeight );
}

sub setVideoMode {    # void ($class, $mode)
  my ( $class, $mode ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $mode );
  $class->setCrtMode( $class->fixCrtMode( $mode ) );
  $class->setCrtData();
  if ( TMouse->present() ) {
    TMouse->setRange( $class->getCols() - 1, $class->getRows() - 1 );
  }
  return;
}

1
