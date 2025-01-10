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
    return Win32::GetOEMCP();
  }
  return 437;
};

INIT: {
  TDisplay->updateIntlChars()
}

sub updateIntlChars {    # void ($class)
  my $class = shift;
  assert ( $class and !ref $class );
  if ( $getCodePage->() != 437 ) {
    require TV::Views::Frame;
    $TV::Views::Frame::frameChars->[30] = "\xCD";
  }
  return;
};

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
