use 5.014;
use warnings;

BEGIN {
  print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
  $| = 1;
}

use Test::More tests => 2;

use TurboVision::Drivers::Win32::EventQ qw( $_ticks );
use TurboVision::Drivers::EventManager qw( :events );

init_events();

ok (
  defined($_ticks),
  'defined $_ticks'
);

my $t1 = $_ticks;
sleep(1);
my $t2 = $_ticks;

cmp_ok (
  $t2, '>', $t1,
  'delta exists'
);

diag('measured delta: ', $t2 - $t1, ' ticks.');

done_events();

done_testing;
