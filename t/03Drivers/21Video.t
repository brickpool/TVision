use 5.014;
use warnings;
use Test::More tests => 8;

BEGIN {
  use_ok 'TurboVision::Drivers::Video';
  use_ok 'TurboVision::Drivers::Const', qw(
    :crXXXX
    :errXXXX
  );
  use_ok 'TurboVision::Drivers::Types', qw( Video );
}

subtest 'Video->error_code' => sub {
  no strict 'subs';
  plan tests => 2;
  Video->clear_screen();
  cmp_ok( Video->error_code, '!=', ERR_OK );
  Video->error_code(0);
  cmp_ok( Video->error_code, '==', ERR_OK );
};

Video->init_video();

is(
  Video->error_code,
  0,
  'Video->init_video'
);

subtest 'Video->get_cursor_type' => sub {
  no strict 'subs';
  plan tests => 2;
  is( Video->get_cursor_type, CR_HIDDEN );
  is( Video->error_code, 0 );
};

subtest 'Video->set_cursor_type' => sub {
  no strict 'subs';
  plan tests => 2;
  Video->set_cursor_type( CR_BLOCK );
  is( Video->get_cursor_type, CR_BLOCK );
  is( Video->error_code, 0 );
};

sleep(1);

Video->done_video();
is(
  Video->error_code,
  0,
  'Video->done_video'
);

done_testing;
