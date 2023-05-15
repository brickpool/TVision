use 5.014;
use warnings;

BEGIN {
  print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
  $| = 1;
}

use Test::More tests => 8;

use Scalar::Util qw( blessed );

require_ok 'TurboVision::Drivers::Const';
require_ok 'TurboVision::Drivers::Types';
require_ok 'TurboVision::Drivers::Win32::EventManager';
require_ok 'TurboVision::Drivers::Win32::Keyboard';
require_ok 'TurboVision::Drivers::Win32::Screen';

use TurboVision::Drivers::Const qw( :kbXXXX :smXXXX :evXXXX );
use TurboVision::Drivers::Types qw( StdioCtl TEvent );
use TurboVision::Drivers::Win32::EventManager qw( :private );
use TurboVision::Drivers::Win32::Keyboard qw( :kbd );
use TurboVision::Drivers::Win32::Screen qw( :screen );

use Win32;
use Win32::Console;
use Win32::GuiTest;

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
my $t0 = my $t1 = Win32::GetTickCount();    # set timer

while ( $t1 - $t0 < 1000 ) {
  my $event = TEvent->new( what => EV_NOTHING );

  my $get_event = do {                      # get events
    my $get_mouse_event = do {
      if (@_event_queue && $_event_queue[0]->what & EV_MOUSE) {
        $event = shift @_event_queue;
      };
      !!$event->what;
    };
    if ( $event->what == EV_NOTHING ) {
      get_key_event($event);
      if ( $event->what == EV_NOTHING ) {
        my $get_system_event = do {
          if (@_event_queue && $_event_queue[0]->what == EV_COMMAND) {
            $event = shift @_event_queue;
          };
          !!$event->what;
        };
        if ( $event->what == EV_NOTHING ) {
          # idle
        }
      }
    }
    !!$event->what;
  };

  if ( $get_event ) {
    my $handle_event = do {                 # handle events
      if ( $event->what ) {
        last  if $event->what == EV_KEY_DOWN
              && $event->key_code == KB_ALT_X
              ;
      }
      !!$event->what;
    };
  }
  
  $t1 = Win32::GetTickCount();
}

cmp_ok (                                    # check delay
  ($t1-$t0), '<', 500
);

done_video();                               # close console

done_testing;
