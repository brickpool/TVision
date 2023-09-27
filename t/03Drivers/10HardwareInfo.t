use 5.014;
use warnings;
use Test::More;
use Test::Exception;
use English qw( -no_match_vars );

BEGIN {
  use_ok 'TurboVision::Drivers::Types', qw( THardwareInfo );
  use_ok 'TurboVision::Drivers::HardwareInfo';
}

my $hw = THardwareInfo->instance();
print "\n";
isa_ok( $hw, THardwareInfo->class() );

subtest 'THardwareInfo->get_tick_count' => sub {
  plan tests => 2;
  ok(
    $hw->get_tick_count(),
    'defined'
  );
  my $t1 = $hw->get_tick_count();
  sleep(1);
  my $t2 = $hw->get_tick_count();
  cmp_ok (
    $t2, '>', $t1,
    'delta exists'
  );
  diag('measured delta: ', $t2 - $t1, ' ticks.');
};

is(
  $hw->get_platform,
  $OSNAME,
  'get_platform'
);

ok(
  defined($hw->get_screen_mode),
  'get_screen_mode'
);

my $cols = $hw->get_screen_cols;
ok(
  defined($cols),
  'get_screen_cols'
);
diag('colums: ', $cols);

my $rows = $hw->get_screen_rows;
ok(
  defined($rows),
  'get_screen_rows'
);
diag('rows: ', $rows);

lives_ok(
  sub {
    $hw->clear_screen($cols, $rows);
  },
  'clear_screen'
);

lives_ok(
  sub {
    $hw->set_screen_mode(80 | 25 << 8);
    $hw->clear_screen(80, 25);
    $hw->set_caret_position(0, 0);
    my $buf = [ map { $_ + 0x8000 } unpack('C*', "world") ];
    $hw->screen_write(10, 10, $buf, scalar @$buf);
  },
  'set_screen_mode, clear_screen, set_caret_position, screen_write'
);

lives_ok(
  sub {
    $hw->_clear_instance();
  },
  '_clear_instance'
);

done_testing();
