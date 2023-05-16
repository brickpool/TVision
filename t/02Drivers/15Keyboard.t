use 5.014;
use warnings;

BEGIN {
  print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
  $| = 1;
}

use Test::More tests => 3;

use Scalar::Util qw( blessed );

use TurboVision::Drivers::Const qw( :kbXXXX :evXXXX );
use TurboVision::Drivers::Types qw( TEvent );
use TurboVision::Drivers::Win32::Keyboard qw( :all );

use Win32;
use Win32::Console;
use Win32::GuiTest;

#----------
note 'subs';
#----------
is(
  get_shift_state(),
  KB_INS_STATE,
  'get_shift_state'
);

my $ev;
get_key_event($ev);
ok(
  blessed( $ev ),
  'get_key_event'
);

#----------------
note 'send Alt-X';
#----------------
Win32::GuiTest::SendKeys("%(x)", 100);
my $t0 = my $t1 = Win32::GetTickCount();

while ( $t1 - $t0 < 1000 ) {
  my $event = TEvent->new( what => EV_NOTHING );
  get_key_event($event);
  last
    if $event->what     == EV_KEY_DOWN
    && $event->key_code == KB_ALT_X
    ;
  $t1 = Win32::GetTickCount();
}

cmp_ok (
  ($t1-$t0), '<', 500, 
  'check delay'
);

done_testing;
