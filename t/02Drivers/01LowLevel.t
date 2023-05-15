use 5.014;
use warnings;

BEGIN {
  print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
  $| = 1;
}

use Test::More tests => 8;

use TurboVision::Drivers::Win32::LowLevel qw(
  GWL_STYLE
  WS_SIZEBOX
  
  GetDoubleClickTime
  FindWindow
  GetWindowLong
  SetWindowLong
);

use Win32::Console;

#---------------
note 'constants';
#---------------
is(
  GWL_STYLE,
  -16,
  'GWL_STYLE'
);

is(
  WS_SIZEBOX,
  0x00040000,
  'WS_SIZEBOX'
);

#---------------
note 'api calls';
#---------------
my $dblclk = GetDoubleClickTime();

ok(
  ( $dblclk > 0 && $dblclk <= 500 ),
  'GetDoubleClickTime'
);

my $CONSOLE = Win32::Console->new();
isa_ok(
  $CONSOLE,
  'Win32::Console'
);

my $title = $CONSOLE->Title();
ok(
  $title,
  '$CONSOLE->Title'
);

my $hWnd = FindWindow(undef, $title);
ok(
  $hWnd,
  'FindWindow'
);

my $dwStyle = GetWindowLong($hWnd, GWL_STYLE);
ok(
  defined $dwStyle,
  'GetWindowLong'
);

ok(
  SetWindowLong($hWnd, GWL_STYLE, $dwStyle),
  'SetWindowLong'
);

done_testing;
