use 5.014;
use warnings;
use Test::More import => [qw( !fail )];   # don't import fail() from Test::More

require_ok 'TurboVision::Drivers';

use TurboVision::Drivers;

is(
  EV_NOTHING,
  0,
  'evXXXX constants'
);

ok(
  defined($screen_mode),
  'screen variables'
);

done_testing;
