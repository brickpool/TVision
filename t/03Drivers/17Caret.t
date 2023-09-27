use 5.014;
use warnings;

BEGIN {
  print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
  $| = 1;
}

use Test::More tests => 2;

BEGIN {
  use_ok 'TurboVision::Drivers::Win32::Caret', qw( :caret );
}

use TurboVision::Drivers::Const qw( :smXXXX );
use TurboVision::Drivers::ScreenManager qw( $cursor_lines );

init_caret();

ok(
  defined($cursor_lines),
  'defined $cursor_lines'
);

sleep(1);
done_caret();

done_testing;
