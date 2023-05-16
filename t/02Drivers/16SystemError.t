use 5.014;
use warnings;

BEGIN {
  print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
  $| = 1;
}

use Test::More tests => 1;

use TurboVision::Drivers::Const qw( :kbXXXX :evXXXX );
use TurboVision::Drivers::Types qw( TEvent );
use TurboVision::Drivers::Win32::Keyboard qw( :kbd );
use TurboVision::Drivers::Win32::SystemError qw( :all );

use Win32;
use Win32::Console;
use Win32::GuiTest;

init_sys_error();

#-----------------
note 'send Ctrl-C';
#-----------------
Win32::GuiTest::SendKeys("^(c)", 100);
my $t0 = my $t1 = Win32::GetTickCount();
  
while ( $t1 - $t0 < 1000 ) {
  my $event = TEvent->new( what => EV_NOTHING );
  get_key_event($event);
  last
    if $event->what == EV_KEY_DOWN
    && get_shift_state() & KB_CTRL_SHIFT
    && $event->key_code == ord "\cC"
    ;
  $t1 = Win32::GetTickCount();
}
  
cmp_ok (
  ($t1-$t0), '<', 500,
  'check delay'
);
  
done_sys_error();

done_testing;
