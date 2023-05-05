use 5.014;
use warnings;

BEGIN {
  print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
  $| = 1;
}

use Test::More tests => 15;

use Scalar::Util qw( blessed );

require_ok 'TurboVision::Drivers::Const';
require_ok 'TurboVision::Drivers::Types';
require_ok 'TurboVision::Drivers::Win32::Keyboard';
require_ok 'TurboVision::Drivers::Win32::Screen';

use TurboVision::Drivers::Const qw( :kbXXXX :smXXXX :evXXXX );
use TurboVision::Drivers::Types qw( StdioCtl TEvent );
use TurboVision::Drivers::Win32::Keyboard qw( :kbd );
use TurboVision::Drivers::Win32::Screen qw( :screen );

use Win32;
use Win32::Console;
use Win32::GuiTest;

is(
  ctrl_to_arrow( KB_CTRL_A ), # Ctrl-A
  KB_HOME,
  'ctrl_to_arrow'
);

is(
  ctrl_to_arrow( "\cF" ), # Ctrl-F
  KB_END,
  'ctrl_to_arrow (as string)'
);

cmp_ok(
  get_alt_char( KB_ALT_A ), 'eq', 'A',
  'get_alt_char'
);

cmp_ok(
  get_alt_char( KB_ALT_SPACE ), 'eq', "\xf0",
  'get_alt_char (special case)'
);

is(
  get_alt_code( 'Z' ),
  KB_ALT_Z,
  'get_alt_code'
);

is(
  get_alt_code( "\xf0" ),
  KB_ALT_SPACE,
  'get_alt_code (special case)'
);

cmp_ok(
  get_ctrl_char( KB_CTRL_A ), 'eq', 'A',
  'get_ctrl_char'
);

is(
  get_ctrl_code( 'Z' ),
  KB_CTRL_Z,
  'get_ctrl_code'
);


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

init_video();                               # create console
set_video_mode(SM_CO80);                    # set default mode

my $CONSOLE = StdioCtl->instance()->out;
$CONSOLE->Write( "Press Alt-X on exit\n" );

Win32::GuiTest::SendKeys("%(x)", 100);      # send Alt-X in 100ms
my $t0 = Win32::GetTickCount();             # start timer

my $exit = 0;
while ( not $exit ) {
  my $event = TEvent->new( what => EV_NOTHING );
  get_key_event($event);
  $exit =  $event->what     == EV_KEY_DOWN
        && $event->key_code == KB_ALT_X
        ;
}

my $t1 = Win32::GetTickCount();             # stop timer
cmp_ok (                                    # check delay
  ($t1-$t0), '<', 500
);

done_video();                               # close console

done_testing;
