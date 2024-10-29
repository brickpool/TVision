package TV::Drivers::Display;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TDisplay
);

use TV::Drivers::HardwareInfo;

sub TDisplay() { __PACKAGE__ }

my $getCodePage = sub {
  if ( $^O eq 'MSWin32' ) {
    require Win32;
    return Win32::GetOEMCP();
  }
  return 437;
};

INIT: {
  TDisplay->updateIntlChars()
}

sub updateIntlChars {    # void ($class)
  my ( $class ) = @_;
  if ( $getCodePage->() != 437 ) {
    ...;
  }
  return;
};

sub getCursorType {    # $size ($class)
  return THardwareInfo->getCaretSize();
}

sub setCursorType {    # void ($class, $ct)
  my ( $class, $ct ) = @_;
  THardwareInfo->setCaretSize( $ct & 0xff );
  return;
}

sub clearScreen {    # void ($class, $w, $h)
  my ( $class, $w, $h ) = @_;
  THardwareInfo->clearScreen( $w, $h );
  return;
}

sub getRows {    # $rows ($class)
  return THardwareInfo->getScreenRows();
}

sub getCols {    # $cols ($class)
  return THardwareInfo->getScreenCols();
}

sub getCrtMode {    # void ($class)
  return THardwareInfo->getScreenMode();
}

sub setCrtMode {    # void ($class, $mode)
  my ( $class, $mode ) = @_;
  THardwareInfo->setScreenMode( $mode );
  return;
}

1
