use 5.014;
use warnings;

BEGIN {
  print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
  $| = 1;
}

use Test::More tests => 1;

use Devel::StrictMode;

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
use TurboVision::Drivers::Win32::EventQ qw( @_event_queue );
use TurboVision::Drivers::Win32::Keyboard qw( :all );
use TurboVision::Drivers::Win32::Mouse qw( :all );
use TurboVision::Drivers::Win32::Screen qw( :all );

use Win32::Console;

init_video();
set_video_mode(SM_CO80);

my $CONSOLE = StdioCtl->instance()->out;
$CONSOLE->Write( "Press Alt-X on exit\n" );

while (1) {
  my $event = TEvent->new( what => EV_NOTHING );

  my $get_event = do {
    get_mouse_event($event);
    if ( $event->what == EV_NOTHING ) {
      get_key_event($event);
      if ( $event->what == EV_NOTHING ) {
        my $get_system_event = do {
          if (@_event_queue && $_event_queue[0]->what & EV_MESSAGE) {
            $event = shift @_event_queue;
          };
          !!$event->what;
        }
      }
    }
    !!$event->what;
  };
  next if !$get_event;

  my $handle_event = do {
    if ( $event->what ) {
      if ( STRICT ) {
        say STDERR $event, 'shift_state : ', get_shift_state(), "\n";
      }
      $CONSOLE->Write( $event->text );
      last if $event->what == EV_KEY_DOWN
           && $event->key_code == KB_ALT_X
           ;
    }
    !!$event->what;
  };
}

done_video();

ok 1;
done_testing;
