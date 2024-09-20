use 5.014;
use warnings;

BEGIN {
  print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
  $| = 1;
}

use Test::More tests => 1;

use TurboVision::Drivers::Const qw(
  :all
  !:private
);
use TurboVision::Drivers::Types qw(
  StdioCtl
  TEvent
);
use TurboVision::Drivers::Event;
use TurboVision::Drivers::Win32::StdioCtl;
use TurboVision::Drivers::Win32::Keyboard qw( :kbd );

use Win32::Console;
use Win32::GuiTest;

my $CONSOLE = StdioCtl->instance()->out;
$CONSOLE->Write( "Press Alt-X on exit\n" );

Win32::GuiTest::SendKeys("%(x)", 100);      # send Alt-X in 100ms
my $t0 = my $t1 = Win32::GetTickCount();    # start timer 0 and 1

while ( $t1 - $t0 < 5000 ) {
  my $event = TEvent->new( what => EV_NOTHING );
  get_key_event($event);
  last
    if $event->what     == EV_KEY_DOWN
    && $event->key_code == KB_ALT_X
    ;
  $t1 = Win32::GetTickCount();              # update timer 1
}

cmp_ok (                                    # check delay
  ($t1-$t0), '<', 500
);

done_testing;
