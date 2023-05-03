use 5.014;
use warnings;
use Test::More;

if( $^O ne 'MSWin32' ) {
  plan skip_all => 'Test relevant only for Windows OS';
}
else {
  plan tests => 3;
}

require_ok 'TurboVision::Drivers::Win32::EventManager';

use TurboVision::Drivers::Win32::EventManager qw( $_ticks );

ok defined($_ticks), 'defined $_ticks';

my $t1 = $_ticks;
sleep(1);
my $t2 = $_ticks;

cmp_ok $t2, '>', $t1, 'delta exists';
diag('measured delta: ', $t2 - $t1, ' ticks.');

done_testing;
