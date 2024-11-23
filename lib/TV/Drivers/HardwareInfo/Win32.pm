package TV::Drivers::HardwareInfo::Win32;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
  THardwareInfo
);

use Data::Alias;
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use English qw( -no_match_vars );
use Scalar::Util qw(
  blessed 
  looks_like_number
  readonly
);
use Win32;
use Win32::Console;
use Win32::Console::PatchForRT33513;
use Win32API::File;

use TV::Drivers::Const qw(
  evKeyDown
  :smXXXX
  kbAltShift
  kbCtrlShift
  kbShift
  kbIns
  kbInsState
  kbCtrlC
);

sub THardwareInfo() { __PACKAGE__ }

PRIVATE: {
  namespace::sweep->import( -also => [qw(
    cnInput
    cnOutput
    dwSize
    bVisible
    dwSizeX
    dwSizeY
    srWindowLeft
    srWindowTop
    srWindowRight
    srWindowBottom
    EventType
    KEY_EVENT
    MOUSE_EVENT
    bKeyDown
    wRepeatCount
    wVirtualKeyCode
    wVirtualScanCode
    uChar
    dwControlKeyState1
    dwMousePositionX
    dwMousePositionY
    dwButtonState
    dwControlKeyState2
    dwEventFlags
  )] ) if eval { require namespace::sweep };

  # ConsoleType
  sub cnInput   (){ 0 }
  sub cnStartup (){ 1 }
  sub cnOutput  (){ 2 }

  # CONSOLE_CURSOR_INFO
  sub dwSize   (){ 2 }
  sub bVisible (){ 3 }

  # CONSOLE_SCREEN_BUFFER_INFO
  sub dwSizeX         (){ 0 }
  sub dwSizeY         (){ 1 }
  sub srWindowLeft    (){ 5 }
  sub srWindowTop     (){ 6 }
  sub srWindowRight   (){ 7 }
  sub srWindowBottom  (){ 8 }

  # INPUT_RECORD
  sub EventType (){ 0 }

  # EventType
  sub KEY_EVENT   (){ 0x0001 }
  sub MOUSE_EVENT (){ 0x0002 }

  # KEY_EVENT_RECORD
  sub bKeyDown            (){ 1 }
  sub wRepeatCount        (){ 2 }
  sub wVirtualKeyCode     (){ 3 }
  sub wVirtualScanCode    (){ 4 }
  sub uChar               (){ 5 }
  sub dwControlKeyState1  (){ 6 }

  # MOUSE_EVENT_RECORD
  sub dwMousePositionX    (){ 1 }
  sub dwMousePositionY    (){ 2 }
  sub dwButtonState       (){ 3 }
  sub dwControlKeyState2  (){ 4 }
  sub dwEventFlags        (){ 5 }
}

# predeclare global variable names
our $insertState   = !!1;
our $platform      = '';
our @consoleHandle = ();
our $ownsConsole   = !!0;
our $consoleMode   = 0;
our $pendingEvent  = 0;
our @irBuffer      = ();
our @crInfo        = ();
our @sbInfo        = ();
{
  no warnings 'once';
  alias THardwareInfo->{insertState}   = $insertState;
  alias THardwareInfo->{platform}      = $platform;
  alias THardwareInfo->{consoleHandle} = @consoleHandle;
  alias THardwareInfo->{ownsConsole}   = $ownsConsole;
  alias THardwareInfo->{consoleMode}   = $consoleMode;
  alias THardwareInfo->{pendingEvent}  = $pendingEvent;
  alias THardwareInfo->{irBuffer}      = @irBuffer;
  alias THardwareInfo->{crInfo}        = @crInfo;
  alias THardwareInfo->{sbInfo}        = @sbInfo;
}

my @ShiftCvt = (
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0, 0x5400, 0x5500, 0x5600, 0x5700, 0x5800,
    0x5900, 0x5a00, 0x5b00, 0x5c00, 0x5d00,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0, 0x0500, 0x0700,      0,      0,      0, 0x8700,
    0x8800
);

my @CtrlCvt = (
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
    0x0011, 0x0017, 0x0005, 0x0012, 0x0014, 0x0019, 0x0015, 0x0009,
    0x000f, 0x0010,      0,      0,      0,      0, 0x0001, 0x0013,
    0x0004, 0x0006, 0x0007, 0x0008, 0x000a, 0x000b, 0x000c,      0,
         0,      0,      0,      0, 0x001a, 0x0018, 0x0003, 0x0016,
    0x0002, 0x000e, 0x000d,      0,      0,      0,      0,      0,
         0,      0,      0, 0x5e00, 0x5f00, 0x6000, 0x6100, 0x6200,
    0x6300, 0x6400, 0x6500, 0x6600, 0x6700,      0,      0, 0x7700,
         0, 0x8400,      0, 0x7300,      0, 0x7400,      0, 0x7500,
         0, 0x7600, 0x0400, 0x0600,      0,      0,      0, 0x8900,
    0x8a00
);

my @AltCvt = (
         0,      0, 0x7800, 0x7900, 0x7a00, 0x7b00, 0x7c00, 0x7d00,
    0x7e00, 0x7f00, 0x8000, 0x8100, 0x8200, 0x8300, 0x0800,      0,
    0x1000, 0x1100, 0x1200, 0x1300, 0x1400, 0x1500, 0x1600, 0x1700,
    0x1800, 0x1900,      0,      0,      0,      0, 0x1e00, 0x1f00,
    0x2000, 0x2100, 0x2200, 0x2300, 0x2400, 0x2500, 0x2600,      0,
         0,      0,      0,      0, 0x2c00, 0x2d00, 0x2e00, 0x2f00,
    0x3000, 0x3100, 0x3200,      0,      0,      0,      0,      0,
         0, 0x0200,      0, 0x6800, 0x6900, 0x6a00, 0x6b00, 0x6c00,
    0x6d00, 0x6e00, 0x6f00, 0x7000, 0x7100,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0, 0x8b00,
    0x8c00
);

my $isValid = sub {    # $bool ($self)
  my ( $self ) = @_;
  return undef unless ref( $self );
  return !!$self->Mode();
};

INIT: {
  my $mod;

  if ( ( $mod = $^O ) && ( $mod ne 'MSWin32' ) ) {
    ...;
  }
  else {
    $platform = 'Windows';
  }

  # The following content was taken from the framework
  # "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
  #
  # Copyright 2019-2021 by magiblot <magiblot@hotmail.com>
  #
  # I<conctl.cpp>
  {
    my $console;
    my $have_console = 0;

    $console = Win32::Console->new( STD_INPUT_HANDLE );
    if ( $console && $console->$isValid() ) {
      $have_console = 1;
      $consoleHandle[cnInput] = $console;
    }
    $console = Win32::Console->new( STD_OUTPUT_HANDLE );
    if ( $console && $console->$isValid() ) {
      $have_console = 1;
      $consoleHandle[cnStartup] = $console;
    }
    $console = Win32::Console->new( STD_ERROR_HANDLE );
    if ( $console && $console->$isValid() ) {
      $have_console = 1;
      $consoleHandle[cnStartup] = $console;
    }

    unless ( $have_console ) {
      Win32::Console::Free();
      Win32::Console::Alloc();
      $ownsConsole = !!1;
    }

    unless ( $consoleHandle[cnInput] ) {
      # Create a new generic object
      $console = Win32::Console->new();
      if ( $console && $console->$isValid() ) {
        # If object is a valid console, close the old handle
        $console->Close();
        # Assign a handle created by CreateFile() to the object
        $console->{handle} = Win32API::File::createFile(
          'CONIN$',
          {
            Access => GENERIC_READ | GENERIC_WRITE,
            Share  => FILE_SHARE_READ,
            Create => Win32API::File::OPEN_EXISTING,
          }
        );
        $consoleHandle[cnInput] = $console;
      }
    }
    unless ( $consoleHandle[cnStartup] ) {
      $console = Win32::Console->new();
      if ( $console && $console->$isValid() ) {
        $console->Close();
        $console->{handle} = Win32API::File::createFile(
          'CONOUT$',
          {
            Access => GENERIC_READ | GENERIC_WRITE,
            Share  => FILE_SHARE_WRITE,
            Create => Win32API::File::OPEN_EXISTING,
          }
        );
        $consoleHandle[cnStartup] = $console;
      }
    }
    $console = Win32::Console->new( GENERIC_READ | GENERIC_WRITE, 0 );
    if ( $console && $console->$isValid() ) {
      $consoleHandle[cnOutput] = $console;
      if ( @sbInfo = $consoleHandle[cnStartup]->Info() ) {
        # Force the screen buffer size to match the window size.
        # The Console API guarantees this, but some implementations
        # are not compliant (e.g. Wine).
        $sbInfo[dwSizeX] = $sbInfo[srWindowRight] - $sbInfo[srWindowLeft] + 1;
        $sbInfo[dwSizeY] = $sbInfo[srWindowBottom] - $sbInfo[srWindowTop] + 1;
        $consoleHandle[cnOutput]->Size( @sbInfo[dwSizeX, dwSizeY] );
      }
      $consoleHandle[cnOutput]->Display();
    }

    die "Error: cannot get a console.\n" 
      unless grep { $_ && $_->$isValid() } @consoleHandle;
  }

  $consoleMode = $consoleHandle[cnInput]->Mode();
  @crInfo      = $consoleHandle[cnOutput]->Cursor();
  @sbInfo      = $consoleHandle[cnOutput]->Info();
}

END {
  $consoleHandle[cnStartup]->Display()
    if $consoleHandle[cnStartup];
  Win32::Console::Free()
    if $ownsConsole;
}

sub getTickCount {    # $ticks ($class)
  assert ( $_[0] and !ref $_[0] );
  # To change units from ms to clock ticks.
  #   X ms * 1s/1000ms * 18.2ticks/s = X/55 ticks, roughly.
  return int( Win32::GetTickCount() / 55 );
}

sub getPlatform {    # $osname ($class)
  assert ( $_[0] and !ref $_[0] );
  return $platform;
}

# Caret functions.

sub setCaretSize {    # void ($class, $size)
  my ( $class, $size ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $size );
  @crInfo = $consoleHandle[cnOutput]->Cursor();
  if ( $size == 0 ) {
    $crInfo[bVisible] = 0;
    $crInfo[dwSize]   = 1;
  }
  else {
    $crInfo[bVisible] = 1;
    $crInfo[dwSize]   = $size;
  }
  $consoleHandle[cnOutput]->Cursor(@crInfo);
  return;
} #/ sub setCaretSize

sub getCaretSize {  # $size ($class)
  assert ( $_[0] and !ref $_[0] );
  return $crInfo[dwSize];
}

sub setCaretPosition { # void ($class, $x, $y)
  my ( $class, $x, $y ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $x );
  assert ( looks_like_number $y );
  $consoleHandle[cnOutput]->Cursor($x, $y);
  return;
}

sub isCaretVisible {  # $visible ($class)
  assert ( $_[0] and !ref $_[0] );
  return $crInfo[bVisible];
}

# Screen functions.

sub getScreenRows { # $rows ($class)
  assert ( $_[0] and !ref $_[0] );
  return $sbInfo[dwSizeY];
}

sub getScreenCols { # $cols ($class)
  assert ( $_[0] and !ref $_[0] );
  return $sbInfo[dwSizeX];
}

sub getScreenMode {    # $mode ($class)
  my $class = shift;
  assert ( $class and !ref $class );
  my $mode  = 0;
  if ( $platform eq 'Windows' ) {
    $mode = smCO80;    # B/W, mono not supported if running on Windows
  }
  if ( $class->getScreenRows() > 25 ) {
    $mode |= smFont8x8;
  }
  return $mode;
} #/ sub getScreenMode

sub setScreenMode {    # void ($class, $mode)
  my ( $class, $mode ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $mode );
  my %newSize = ( X => 80, Y => 25 );
  my %rect    = ( Left => 0, Top => 0, Right => 79, Bottom => 24 );

  if ( $mode & smFont8x8 ) {
    $newSize{Y}   = 50;
    $rect{Bottom} = 49;
  }

  if ( $platform eq 'Windows' ) {
    my ( $maxSizeX, $maxSizeY ) = $consoleHandle[cnOutput]->MaxWindow();
    if ( $newSize{Y} > $maxSizeY ) {
      $newSize{Y}   = $maxSizeY;
      $rect{Bottom} = $newSize{Y} - 1;
    }
  }

  if ( $mode & smFont8x8 ) {
    $consoleHandle[cnOutput]->Size( @newSize{qw(X Y)} );
    $consoleHandle[cnOutput]->Window( @rect{qw(Left Top Right Bottom)} );
  }
  else {
    $consoleHandle[cnOutput]->Window( @rect{qw(Left Top Right Bottom)} );
    $consoleHandle[cnOutput]->Size( @newSize{qw(X Y)} );
  }

  @sbInfo = $consoleHandle[cnOutput]->Size();
  return;
} #/ sub setScreenMode

sub clearScreen {    # void ($class, $w, $h);
  my ( $class, $w, $h ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $w );
  assert ( looks_like_number $h );
  $consoleHandle[cnOutput]->FillAttr( 0x07, $w * $h, 0, 0 );
  $consoleHandle[cnOutput]->FillChar( ' ', $w * $h, 0, 0 );
  return;
}

sub screenWrite {    # void ($class, $x, $y, $buf, $len)
  my ( $class, $x, $y, $buf, $len ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $x );
  assert ( looks_like_number $y );
  assert ( ref $buf );
  assert ( looks_like_number $len );
  my %to = ( Left => $x, Top => $y, Right => $x + $len - 1, Bottom => $y );

  $consoleHandle[cnOutput]->WriteRect( 
    pack( 'S*', @$buf ), @to{qw(Left Top Right Bottom)} 
  );
  return;
}

sub allocateScreenBuffer {    # \@buffer ($class)
  assert ( $_[0] and !ref $_[0] );
  my $x = $sbInfo[dwSizeX];
  my $y = $sbInfo[dwSizeY];

  # Make sure we allocate at least enough for a 80x50 screen.
  $x = 80 if $x < 80;
  $y = 50 if $y < 50;

  return [ ( 0 ) x ( $x * $y * 2 ) ];
}

sub freeScreenBuffer {  #  void ($class, \@buffer)
  assert ( $_[0] and !ref $_[0] );
  assert ( ref $_[1] and !readonly @{$_[1]} );
  $_[1] = [];
  return;
}

# Mouse functions.

sub getButtonCount {    # $num ($class)
  assert ( $_[0] and !ref $_[0] );
  require Win32Native;
  my $num = 0;
  Win32Native::GetNumberOfConsoleMouseButtons( $num );
  return $num;
}

sub cursorOn {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  $consoleHandle[cnInput]->Mode( $consoleMode | ENABLE_MOUSE_INPUT );
  return;
}

sub cursorOff {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  $consoleHandle[cnInput]->Mode( $consoleMode & ~ENABLE_MOUSE_INPUT );
  return;
}

# Event functions.

sub clearPendingEvent {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  $pendingEvent = 0;
  return;
}

sub getMouseEvent {    # $bool ($class, $event)
  my ( $class, $event ) = @_;
  assert ( $class and !ref $class );
  assert ( blessed $event );
  if ( !$pendingEvent ) {
    $pendingEvent = $consoleHandle[cnInput]->GetEvents();
    if ( $pendingEvent ) {
      @irBuffer = $consoleHandle[cnInput]->Input();
    }
  }

  if ( $pendingEvent && $irBuffer[EventType] == MOUSE_EVENT ) {
    $event->{where}{x}        = $irBuffer[dwMousePositionX];
    $event->{where}{y}        = $irBuffer[dwMousePositionY];
    $event->{buttons}         = $irBuffer[dwButtonState];
    $event->{eventFlags}      = $irBuffer[dwEventFlags];
    $event->{controlKeyState} = $irBuffer[dwControlKeyState2];

    $pendingEvent = 0;
    return !!1;
  } #/ if ( $pendingEvent && ...)
  return !!0;
} #/ sub getMouseEvent

sub getKeyEvent {    # $bool ($class, $event)
  my ( $class, $event ) = @_;
  assert ( $class and !ref $class );
  assert ( blessed $event );
  if ( !$pendingEvent ) {
    $pendingEvent = $consoleHandle[cnInput]->GetEvents();
    if ( $pendingEvent ) {
      @irBuffer = $consoleHandle[cnInput]->Input();
    }
  }

  if ( $pendingEvent ) {
    if ( $irBuffer[EventType] == KEY_EVENT && $irBuffer[bKeyDown] ) {
      $event->{what}                        = evKeyDown;
      $event->{keyDown}{charScan}{scanCode} = $irBuffer[wVirtualScanCode];
      $event->{keyDown}{charScan}{charCode} = $irBuffer[uChar];
      $event->{keyDown}{controlKeyState}    = $irBuffer[dwControlKeyState1];

      # Convert Windows style virtual scan codes to PC BIOS codes.
      if ( $event->{keyDown}{controlKeyState} &
        ( kbShift | kbAltShift | kbCtrlShift ) 
      ) {
        my $index = $irBuffer[wVirtualScanCode];

        if ( ( $event->{keyDown}{controlKeyState} & kbShift )
          && $ShiftCvt[$index] 
        ) {
          $event->{keyDown}{keyCode} = $ShiftCvt[$index];
        }
        elsif ( ( $event->{keyDown}{controlKeyState} & kbCtrlShift )
          && $CtrlCvt[$index] 
        ) {
          $event->{keyDown}{keyCode} = $CtrlCvt[$index];
        }
        elsif ( ( $event->{keyDown}{controlKeyState} & kbAltShift )
          && $AltCvt[$index] 
        ) {
          $event->{keyDown}{keyCode} = $AltCvt[$index];
        }
      } #/ if ( $event->{keyDown}...)

      # Set/Reset insert flag.
      if ( $event->{keyDown}{keyCode} == kbIns ) {
        $insertState = !$insertState;
      }

      if ( $insertState ) {
        $event->{keyDown}{controlKeyState} |= kbInsState;
      }

      if ( $event->{keyDown}{keyCode} == kbCtrlC ) {
        no warnings 'once';
        $TSystemError::ctrlBreakHit = !!1;
      }

      $pendingEvent = 0;
      return !!1;
    } #/ if ( $irBuffer[EventType...])
    elsif ( $irBuffer[EventType] != MOUSE_EVENT ) {
      # Ignore all events except mouse events.  Pending mouse events will
      # be read on the next polling loop.
      $pendingEvent = 0;
    }
  } #/ if ( $pendingEvent )

  return !!0;
} #/ sub getKeyEvent

# System functions.

sub setCtrlBrkHandler { # $success ($class, $install)
  my ( $class, $install ) = @_;
  assert ( $class and !ref $class );
  assert ( !defined $install or !ref $install );
  assert ( @_ == 2 );
  return $consoleHandle[cnInput]->Mode(
    $install 
      ? $consoleMode & ~ENABLE_PROCESSED_INPUT 
      : $consoleMode | ENABLE_PROCESSED_INPUT
  );
}

sub setCritErrorHandler {  # $bool ($class, $install)
  assert ( $_[0] and !ref $_[0] );
  assert ( !defined $_[1] or !ref $_[1] );
  assert ( @_ == 2 );
  # Handled by Windows
  return !!1;
}

my $ctrlBreakHandler = sub { ... };

package Win32Native {
  use Win32::API;
  BEGIN {
    Win32::API::More->Import('kernel32',
      'BOOL GetNumberOfConsoleMouseButtons(
        LPDWORD lpNumberOfMouseButtons
      )'
    ) or die "Import GetNumberOfConsoleMouseButtons: $^E";
  }

  $INC{"Win32Native.pm"} = 1;
}

1
