use 5.014;
use warnings;

BEGIN {
  print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
  $| = 1;
}

use Test::More tests => 7;

BEGIN {
  use_ok 'Win32::Console';
  use_ok 'TurboVision::Drivers::Win32::Console';
}

can_ok(
  'Win32::Console',
  qw(
    _GetCurrentConsoleFont
    Close
    isConsole
  )
);

my $CONSOLE = Win32::Console->new();

my @font_info = Win32::Console::_GetCurrentConsoleFont($CONSOLE->{handle}, !!0);
is (
  scalar @font_info,
  3,
  'Win32::Console::_GetCurrentConsoleFont',
);

isa_ok(
  $CONSOLE,
  'Win32::Console'
);

ok(
  $CONSOLE->{_patched},
  '$CONSOLE is patched'
);

ok(
  $CONSOLE->isConsole,
  '$CONSOLE->isConsole'
);

done_testing;
