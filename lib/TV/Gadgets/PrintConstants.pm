package TV::Gadgets::PrintConstants;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
  printFlags
  printCode
  printKeyCode
  printControlKeyState
  printEventCode
  printMouseButtonState
  printMouseWheelState
  printMouseEventFlags
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( looks_like_number );

use TV::Drivers::Const qw(
  :evXXXX
  :kbXXXX
  :mbXXXX
  :meXXXX
);

{
  no strict 'refs';
  sub NM ($) { ( &{ $_[0] }() => $_[0] ) }
  sub NMEND () { ( 0 => '0' ) }
}

my %keyCodes = (
  NM( 'kbCtrlA' ),     NM( 'kbCtrlB' ),    NM( 'kbCtrlC' ),
  NM( 'kbCtrlD' ),     NM( 'kbCtrlE' ),    NM( 'kbCtrlF' ),
  NM( 'kbCtrlG' ),     NM( 'kbCtrlH' ),    NM( 'kbCtrlI' ),
  NM( 'kbCtrlJ' ),     NM( 'kbCtrlK' ),    NM( 'kbCtrlL' ),
  NM( 'kbCtrlM' ),     NM( 'kbCtrlN' ),    NM( 'kbCtrlO' ),
  NM( 'kbCtrlP' ),     NM( 'kbCtrlQ' ),    NM( 'kbCtrlR' ),
  NM( 'kbCtrlS' ),     NM( 'kbCtrlT' ),    NM( 'kbCtrlU' ),
  NM( 'kbCtrlV' ),     NM( 'kbCtrlW' ),    NM( 'kbCtrlX' ),
  NM( 'kbCtrlY' ),     NM( 'kbCtrlZ' ),
  NM( 'kbEsc' ),       NM( 'kbAltSpace' ), NM( 'kbCtrlIns' ),
  NM( 'kbShiftIns' ),  NM( 'kbCtrlDel' ),  NM( 'kbShiftDel' ),
  NM( 'kbBack' ),      NM( 'kbCtrlBack' ), NM( 'kbShiftTab' ),
  NM( 'kbTab' ),       NM( 'kbAltQ' ),     NM( 'kbAltW' ),
  NM( 'kbAltE' ),      NM( 'kbAltR' ),     NM( 'kbAltT' ),
  NM( 'kbAltY' ),      NM( 'kbAltU' ),     NM( 'kbAltI' ),
  NM( 'kbAltO' ),      NM( 'kbAltP' ),     NM( 'kbCtrlEnter' ),
  NM( 'kbEnter' ),     NM( 'kbAltA' ),     NM( 'kbAltS' ),
  NM( 'kbAltD' ),      NM( 'kbAltF' ),     NM( 'kbAltG' ),
  NM( 'kbAltH' ),      NM( 'kbAltJ' ),     NM( 'kbAltK' ),
  NM( 'kbAltL' ),      NM( 'kbAltZ' ),     NM( 'kbAltX' ),
  NM( 'kbAltC' ),      NM( 'kbAltV' ),     NM( 'kbAltB' ),
  NM( 'kbAltN' ),      NM( 'kbAltM' ),     NM( 'kbF1' ),
  NM( 'kbF2' ),        NM( 'kbF3' ),       NM( 'kbF4' ),
  NM( 'kbF5' ),        NM( 'kbF6' ),       NM( 'kbF7' ),
  NM( 'kbF8' ),        NM( 'kbF9' ),       NM( 'kbF10' ),
  NM( 'kbHome' ),      NM( 'kbUp' ),       NM( 'kbPgUp' ),
  NM( 'kbGrayMinus' ), NM( 'kbLeft' ),     NM( 'kbRight' ),
  NM( 'kbGrayPlus' ),  NM( 'kbEnd' ),      NM( 'kbDown' ),
  NM( 'kbPgDn' ),      NM( 'kbIns' ),      NM( 'kbDel' ),
  NM( 'kbShiftF1' ),   NM( 'kbShiftF2' ),  NM( 'kbShiftF3' ),
  NM( 'kbShiftF4' ),   NM( 'kbShiftF5' ),  NM( 'kbShiftF6' ),
  NM( 'kbShiftF7' ),   NM( 'kbShiftF8' ),  NM( 'kbShiftF9' ),
  NM( 'kbShiftF10' ),  NM( 'kbCtrlF1' ),   NM( 'kbCtrlF2' ),
  NM( 'kbCtrlF3' ),    NM( 'kbCtrlF4' ),   NM( 'kbCtrlF5' ),
  NM( 'kbCtrlF6' ),    NM( 'kbCtrlF7' ),   NM( 'kbCtrlF8' ),
  NM( 'kbCtrlF9' ),    NM( 'kbCtrlF10' ),  NM( 'kbAltF1' ),
  NM( 'kbAltF2' ),     NM( 'kbAltF3' ),    NM( 'kbAltF4' ),
  NM( 'kbAltF5' ),     NM( 'kbAltF6' ),    NM( 'kbAltF7' ),
  NM( 'kbAltF8' ),     NM( 'kbAltF9' ),    NM( 'kbAltF10' ),
  NM( 'kbCtrlPrtSc' ), NM( 'kbCtrlLeft' ), NM( 'kbCtrlRight' ),
  NM( 'kbCtrlEnd' ),   NM( 'kbCtrlPgDn' ), NM( 'kbCtrlHome' ),
  NM( 'kbAlt1' ),      NM( 'kbAlt2' ),     NM( 'kbAlt3' ),
  NM( 'kbAlt4' ),      NM( 'kbAlt5' ),     NM( 'kbAlt6' ),
  NM( 'kbAlt7' ),      NM( 'kbAlt8' ),     NM( 'kbAlt9' ),
  NM( 'kbAlt0' ),      NM( 'kbAltMinus' ), NM( 'kbAltEqual' ),
  NM( 'kbCtrlPgUp' ),  NM( 'kbNoKey' ),
  # NM( 'kbAltEsc' ),   
                       NM( 'kbAltBack' ),  NM( 'kbF11' ),
  NM( 'kbF12' ),       NM( 'kbShiftF11' ), NM( 'kbShiftF12' ),
  NM( 'kbCtrlF11' ),   NM( 'kbCtrlF12' ),  NM( 'kbAltF11' ),
  NM( 'kbAltF12' ),    # NM( 'kbCtrlUp' ),   NM( 'kbCtrlDown' ),
  # NM( 'kbCtrlTab' ),   NM( 'kbAltHome' ),  NM( 'kbAltUp' ),
  # NM( 'kbAltPgUp' ),   NM( 'kbAltLeft' ),  NM( 'kbAltRight' ),
  # NM( 'kbAltEnd' ),    NM( 'kbAltDown' ),  NM( 'kbAltPgDn' ),
  # NM( 'kbAltIns' ),    NM( 'kbAltDel' ),   NM( 'kbAltTab' ),
  # NM( 'kbAltEnter' ),
  NMEND(),
);

my %controlKeyStateFlags = (
  NM( 'kbLeftShift' ),
  NM( 'kbRightShift' ),
  NM( 'kbCtrlShift' ),
  NM( 'kbAltShift' ),
  NM( 'kbShift' ),
  NM( 'kbScrollState' ),
  NM( 'kbLeftCtrl' ),
  NM( 'kbRightCtrl' ),
  NM( 'kbLeftAlt' ),
  NM( 'kbRightAlt' ),
  NM( 'kbNumState' ),
  NM( 'kbCapsState' ),
  NM( 'kbInsState' ),
  NM( 'kbEnhanced' ),
  # NM( 'kbPaste' ),
  NMEND(),
);

my %eventCodes = (
  NM( 'evNothing' ),
  NM( 'evMouseDown' ),
  NM( 'evMouseUp' ),
  NM( 'evMouseMove' ),
  NM( 'evMouseAuto' ),
  # NM( 'evMouseWheel' ),
  NM( 'evMouse' ),
  NM( 'evKeyDown' ),
  NM( 'evCommand' ),
  NM( 'evBroadcast' ),
  NMEND(),
);

my %mouseButtonFlags = (
  NM( 'mbLeftButton' ),
  NM( 'mbRightButton' ),
  # NM( 'mbMiddleButton' ),
  NMEND(),
);

my %mouseWheelFlags = (
  # NM( 'mwUp' ),
  # NM( 'mwDown' ),
  # NM( 'mwLeft' ),
  # NM( 'mwRight' ),
  NMEND(),
);

my %mouseEventFlags = (
  NM( 'meMouseMoved' ),
  NM( 'meDoubleClick' ),
  # NM( 'meTripleClick' ),
  NMEND(),
);

sub printFlags {
  my ( $os, $flags, $constants ) = @_;
  assert ( @_ == 3 );
  assert ( ref $os );
  assert ( looks_like_number $flags );
  assert ( ref $constants );

  my $foundFlags = 0;
  while ( my ( $value, $name ) = each %$constants ) {
    if ( $flags & $value ) {
      $os->print( ' | ' ) if $foundFlags;
      $os->print( $name );
      $foundFlags |= $flags & $value;
    }
  }
  if ( $foundFlags == 0 || $foundFlags != $flags ) {
    $os->print( ' | ' ) if $foundFlags;
    $os->printf( "0x%04X", $flags & ~$foundFlags );
  }
  return;
} #/ sub printFlags

sub printCode {
  my ( $os, $code, $constants ) = @_;
  assert ( @_ == 3 );
  assert ( ref $os );
  assert ( looks_like_number $code );
  assert ( ref $constants );

  if ( exists $constants->{$code} ) {
    $os->print( $constants->{$code} );
    return;
  }

  $os->printf( "0x%04X", $code );
  return;
} #/ sub printCode

sub printKeyCode {
  my ( $os, $keyCode ) = @_;
  printCode( $os, $keyCode, \%keyCodes );
  return;
}

sub printControlKeyState {
  my ( $os, $controlKeyState ) = @_;
  printFlags( $os, $controlKeyState, \%controlKeyStateFlags );
  return;
}

sub printEventCode {
  my ( $os, $eventCode ) = @_;
  printCode( $os, $eventCode, \%eventCodes );
  return;
}

sub printMouseButtonState {
  my ( $os, $buttonState ) = @_;
  printFlags( $os, $buttonState, \%mouseButtonFlags );
  return;
}

sub printMouseWheelState {
  my ( $os, $wheelState ) = @_;
  printFlags( $os, $wheelState, \%mouseWheelFlags );
  return;
}

sub printMouseEventFlags {
  my ( $os, $eventFlags ) = @_;
  printFlags( $os, $eventFlags, \%mouseEventFlags );
  return;
}

1
