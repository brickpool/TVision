use 5.014;
use warnings;
use Test::More tests => 12;

use TurboVision::Drivers::Event;
use TurboVision::Drivers::Types qw( TEvent );
use TurboVision::Drivers::Const qw( :evXXXX );

my $ev = TEvent->new( what => EV_MESSAGE, info_long => 1 );
isa_ok(
  $ev,
  TEvent->class(),
);

is(
  TEvent->new->what, EV_NOTHING,
  'TEvent->new'
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

subtest 'EV_BROADCAST' => sub {
  plan tests => 3;   
  my $obj = bless {};
  for ( $ev = TEvent->new() ) {
    $_->what( EV_BROADCAST );
    $_->command( 700 );
    $_->info_ptr( $obj );
  }
  is( $ev->what, EV_BROADCAST, 'TEvent->what' );
  is( $ev->command, 700, 'TEvent->command' );
  is( $ev->info_ptr, $obj, , 'TEvent->info_ptr' );
};

done_testing;
