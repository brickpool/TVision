use 5.014;
use warnings;
use Test::More tests => 3;

BEGIN {
  use_ok 'TurboVision::Drivers::Video';
  use_ok 'TurboVision::Drivers::Types', qw( Video );
}

Video->init_video();

ok 1;

sleep(1);
Video->done_video();

done_testing;
