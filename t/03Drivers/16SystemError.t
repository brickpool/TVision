use 5.014;
use warnings;
use constant::boolean;

BEGIN {
  print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
  $| = 1;
}
use Test::More tests => 7;

use TurboVision::Drivers::Const qw( :kbXXXX :evXXXX );
use TurboVision::Drivers::Types qw( TEvent );
use TurboVision::Drivers::EventManager qw( :kbd );
use TurboVision::Drivers::SystemError qw( :all );

use Win32;
use Win32::GuiTest;

init_sys_error();

#----------
note 'vars';
#----------
ok (
  $sys_err_active, 
  '$sys_err_active'
);

ok (
  !$fail_sys_errors,
  '$fail_sys_errors'
);

ok (
  !$ctrl_break_hit, 
  '$ctrl_break_hit'
);

#-----------------
note 'SystemError';
#-----------------
use constant ERR => 9;
$fail_sys_errors = TRUE;
my $ret = eval {
  Win32::SetLastError(ERR + 19);
  $sys_error_func->(ERR, 0);
};
ok(
  $ret,
  '$sys_error_func'
);

#------------
note 'Ctrl-C';
#------------
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

ok (
  $ctrl_break_hit,
  '$ctrl_break_hit'
);

done_sys_error();

ok (
  !$sys_err_active, 
  '$sys_err_active'
);

done_testing;
