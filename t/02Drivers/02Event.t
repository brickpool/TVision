use 5.014;
use warnings;
use Test::More tests => 10;

use TurboVision::Drivers::Event;
use TurboVision::Drivers::Types qw( TEvent );
use TurboVision::Drivers::Const qw( :evXXXX );

my $ev = TEvent->new( what => EV_MESSAGE, info_long => 1 );
isa_ok(
  $ev,
  TEvent->class(),
);

ok(
  !defined $ev->info_ptr(undef),
  'TEvent->info_ptr'
);

is(
  $ev->info_int(),
  0,
  'TEvent->info_ptr && TEvent->info_int'
);

is(
  $ev->info_word(0xffff2500),
  0x2500,
  'TEvent->info_word'
);

is(
  ord $ev->info_char(),
  0x2500,
  'TEvent->info_word && TEvent->info_char'
);

is(
  ord($ev->info_char("\x{2501}")),
  0x2501,
  'Unicode && TEvent->info_char'
);

is(
  $ev->info_byte(),
  1,
  'TEvent->info_byte'
);

is(
  $ev->info_int(0xffff),
  -1,
  'TEvent->info_int'
);

is(
  $ev->info_long(0x80000000),
  -2**31,
  'TEvent->info_long'
);

ok(
  length($ev) > 100,
  'TEvent->stringify'
);

done_testing;
