use 5.014;
use warnings;

use Test::More tests => 10;
use Test::Exception;

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

subtest 'Video->get_video_mode' => sub {
  no strict 'subs';
  plan tests => 2;
  my $mode = {
    col   => 0,
    row   => 0,
    color => 0,
  };
  Video->get_video_mode($mode);
  is( Video->error_code, 0 );
  is_deeply($mode, { 
    col   => Video->screen_width,
    row   => Video->screen_height,
    color => Video->screen_color,
  });
};

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

subtest 'Video->update_screen' => sub {
  no strict 'subs';
  plan tests => 3;
  my $w = Video->screen_width;
  my $buf = Video->video_buf;
  ok( $w && $buf );
  $buf->[3 + 2 * $w] = (0x17 << 8) + ord('a');
  $buf->[4 + 2 * $w] = (0x17 << 8) + ord('b');
  $buf->[5 + 2 * $w] = (0x17 << 8) + ord('c');
  $buf->[3 + 3 * $w] = (0x20 << 8) + ord('A');
  $buf->[4 + 3 * $w] = (0x20 << 8) + ord('B');
  $buf->[5 + 3 * $w] = (0x20 << 8) + ord('C');
  lives_ok { Video->update_screen(1) };
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
