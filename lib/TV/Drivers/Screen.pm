package TV::Drivers::Screen;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TScreen
);

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
  *TScreen::startupMode    = \$startupMode;
  *TScreen::startupCursor  = \$startupCursor;
  *TScreen::screenMode     = \$screenMode;
  *TScreen::screenWidth    = \$screenWidth;
  *TScreen::screenHeight   = \$screenHeight;
  *TScreen::hiResScreen    = \$hiResScreen;
  *TScreen::checkSnow      = \$checkSnow;
  *TScreen::screenBuffer   = \$screenBuffer;
  *TScreen::cursorLines    = \$cursorLines;
  *TScreen::clearOnSuspend = \$clearOnSuspend;
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
  $screenMode   = $class->getCrtMode();
  $screenWidth  = $class->getCols();
  $screenHeight = $class->getRows();
  $hiResScreen  = $screenHeight > 25;

  $cursorLines = $class->getCursorType();
  $class->setCursorType( 0 );
  return;
} #/ sub setCrtData

sub clearScreen {    # void ($class)
  TDisplay->clearScreen( $screenWidth, $screenHeight );
}

sub setVideoMode {    # void ($class, $mode)
  my ( $class, $mode ) = @_;
  $class->setCrtMode( $class->fixCrtMode( $mode ) );
  $class->setCrtData();
  if ( TMouse->present() ) {
    TMouse->setRange( $class->getCols() - 1, $class->getRows() - 1 );
  }
  return;
}

1
