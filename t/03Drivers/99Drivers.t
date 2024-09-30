use 5.014;
use warnings;

use Test::More tests => 6;

BEGIN {
  use_ok 'TurboVision::Drivers';
}

#------------------
note 'random check';
#------------------
is(
  EV_NOTHING,
  0,
  'evXXXX constants'
);

ok(
  defined($screen_mode),
  'screen variables'
);

my $ev = TEvent->new( what => EV_MESSAGE, info_long => 1 );
isa_ok(
  $ev,
  TEvent->class(),
);

is(
  ctrl_to_arrow( KB_CTRL_A ),
  KB_HOME,
  'ctrl_to_arrow'
);

ok (
  !$sys_err_active, 
  '$sys_err_active'
);

done_testing;
