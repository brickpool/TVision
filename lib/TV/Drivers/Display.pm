package TV::Drivers::Display;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TDisplay
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( looks_like_number );

use TV::Drivers::HardwareInfo;

sub TDisplay() { __PACKAGE__ }

my $getCodePage = sub {
  if ( $^O eq 'MSWin32' ) {
    require Win32;
    return Win32::GetConsoleOutputCP();
  }
  return 437;
};

INIT {
  TDisplay->updateIntlChars()
}

sub updateIntlChars {    # void ($class)
  my $class = shift;
  assert( $class and !ref $class );
  my $cp = $getCodePage->();
  # Some 8-bit code pages are supported directly.
  return 
    if $cp =~ /^(437|720|737|775|850|852|855|857|858|859|860|861|862|863|865)$/
    || $cp =~ /^(866|869)$/;

  require TV::Views::Frame;
  require TV::Views::ScrollBar;
  require TV::Menus::MenuBox;
  require TV::App::DeskTop;
  if ( $cp == 874 ) {
    $TV::Views::Frame::frameChars    = "   ' :.+ '\x96+.+++   ' |.+ '\x97+.++ ";
    $TV::Views::Frame::closeIcon     = "[~x~]";
    $TV::Views::Frame::zoomIcon      = "[~+~]";
    $TV::Views::Frame::unZoomIcon    = "[~-~]";
    $TV::Views::Frame::dragIcon      = "~\x97'~";
    $TV::Views::ScrollBar::vChars    = "^v # ";
    $TV::Views::ScrollBar::hChars    = "<> # ";
    $TV::Menus::MenuBox::frameChars  = " .-.  '-'  | |  +-+ ";
    $TV::App::DeskTop::defaultBkgrnd = ":";
  }
  elsif ( $cp =~ /^(1250|1251|1252|1253|1254|1256|1257|1258)$/ ) {
    $TV::Views::Frame::frameChars    = "   ' \xA6.+ '\x96+.+++   ' |.+ '\x97+.+"
                                     . "+ ";
    $TV::Views::Frame::closeIcon     = "[~\xD7~]";
    $TV::Views::Frame::zoomIcon      = "[~+~]";
    $TV::Views::Frame::unZoomIcon    = "[~\xB1~]";
    $TV::Views::Frame::dragIcon      = "~\x97'~";
    $TV::Views::ScrollBar::vChars    = "^v \xA4 ";
    $TV::Views::ScrollBar::hChars    = "<> \xA4 ";
    $TV::Menus::MenuBox::frameChars  = " .\x97.  '\x97'  | |  +\x97+ ";
    $TV::App::DeskTop::defaultBkgrnd = ":";
  }
  elsif ( $cp == 1255 ) {
    $TV::Views::Frame::frameChars    = "   ' :.+ '\x96+.+++   ' |.+ '\x97+.++ ";
    $TV::Views::Frame::closeIcon     = "[~x~]";
    $TV::Views::Frame::zoomIcon      = "[~+~]";
    $TV::Views::Frame::unZoomIcon    = "[~\xB1~]";
    $TV::Views::Frame::dragIcon      = "~\x97'~";
    $TV::Views::ScrollBar::vChars    = "^v # ";
    $TV::Views::ScrollBar::hChars    = "<> # ";
    $TV::Menus::MenuBox::frameChars  = " .\x97.  '\x97'  | |  +\x97+ ";
    $TV::App::DeskTop::defaultBkgrnd = ":";
  }
  else {
    $TV::Views::Frame::frameChars    = "   ' :.+ '-+.+++   ' |.+ '=+.++ ";
    $TV::Views::Frame::closeIcon     = "[~x~]";
    $TV::Views::Frame::zoomIcon      = "[~+~]";
    $TV::Views::Frame::unZoomIcon    = "[~-~]";
    $TV::Views::Frame::dragIcon      = "~-'~";
    $TV::Views::ScrollBar::vChars    = "^v # ";
    $TV::Views::ScrollBar::hChars    = "<> # ";
    $TV::Menus::MenuBox::frameChars  = " .-.  '-'  | |  +-+ ";
    $TV::App::DeskTop::defaultBkgrnd = ":";
  }
  return;
} #/ sub updateIntlChars

sub getCursorType {    # $size ($class)
  assert ( $_[0] and !ref $_[0] );
  return THardwareInfo->getCaretSize();
}

sub setCursorType {    # void ($class, $ct)
  my ( $class, $ct ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $ct );
  THardwareInfo->setCaretSize( $ct & 0xff );
  return;
}

sub clearScreen {    # void ($class, $w, $h)
  my ( $class, $w, $h ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $w );
  assert ( looks_like_number $h );
  THardwareInfo->clearScreen( $w, $h );
  return;
}

sub getRows {    # $rows ($class)
  assert ( $_[0] and !ref $_[0] );
  return THardwareInfo->getScreenRows();
}

sub getCols {    # $cols ($class)
  assert ( $_[0] and !ref $_[0] );
  return THardwareInfo->getScreenCols();
}

sub getCrtMode {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  return THardwareInfo->getScreenMode();
}

sub setCrtMode {    # void ($class, $mode)
  my ( $class, $mode ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $mode );
  THardwareInfo->setScreenMode( $mode );
  return;
}

1
