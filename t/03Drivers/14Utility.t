use 5.014;
use warnings;

use Test::More tests => 19;

use TurboVision::Drivers::Const qw( :kbXXXX );
use TurboVision::Drivers::Utility qw( :all );

#-------------------------------
note 'Keyboard support routines';
#-------------------------------
is(
  ctrl_to_arrow( KB_CTRL_A ), # Ctrl-A
  KB_HOME,
  'ctrl_to_arrow'
);

is(
  ctrl_to_arrow( "\cF" ), # Ctrl-F
  KB_END,
  'ctrl_to_arrow (as string)'
);

cmp_ok(
  get_alt_char( KB_ALT_A ), 'eq', 'A',
  'get_alt_char'
);

cmp_ok(
  get_alt_char( KB_ALT_SPACE ), 'eq', "\xf0",
  'get_alt_char (special case)'
);

is(
  get_alt_code( 'Z' ),
  KB_ALT_Z,
  'get_alt_code'
);

is(
  get_alt_code( "\xf0" ),
  KB_ALT_SPACE,
  'get_alt_code (special case)'
);

cmp_ok(
  get_ctrl_char( KB_CTRL_A ), 'eq', 'A',
  'get_ctrl_char'
);

is(
  get_ctrl_code( 'Z' ),
  KB_CTRL_Z,
  'get_ctrl_code'
);

#---------------------
note 'String routines';
#---------------------
my $result = '';
format_str($result, "<%7s>", 'String');
cmp_ok(
  $result, 'eq', '<String>',
  'format_str <String>'
);

format_str($result, "<%-7s>", 'String');
cmp_ok(
  $result, 'eq', '<String >',
  'format_str <String >'
);

format_str($result, "<%4s>", 'String');
cmp_ok(
  $result, 'eq', '<ring>',
  'format_str <ring>'
);

format_str($result, "<%-3s>", 'String');
cmp_ok(
  $result, 'eq', '<Str>',
  'format_str <Str>'
);

format_str($result, "<%07s>", 'String');
cmp_ok(
  $result, 'eq', '<0String>',
  'format_str <0String>'
);

format_str($result, "<%-07s>", 'String');
cmp_ok(
  $result, 'eq', '<String0>',
  'format_str <String0>'
);

#--------------------------
note 'Buffer move routines';
#--------------------------

is (
  c_str_len( '~F~ile' ),
  4,
  'c_str_len'
);

my $a_buffer = [];
move_c_str( $a_buffer, 'This ~is~ some text.', 0x07, 0x70 );
my $str = join('', map { chr($_ & 0xff) } @{ $a_buffer } );
ok (
  length($str) == 18
    &&
  ($a_buffer->[4] >> 8) == 0x70
    &&
  ($a_buffer->[6] >> 8) == 0x07
    &&
  ($a_buffer->[7] >> 8) == 0x70
  ,
  'move_c_str'
);

my $src = $a_buffer;
my $dest = [];
move_buf($dest, $src, 0x77, 5);
$str = join('', map { chr($_ & 0xff) } @{ $dest } );
ok (
  length($str) == 5
    &&
  ($dest->[4] & 0xff) == ($src->[4] & 0xff)
    &&
  ($dest->[4] >> 8) == 0x77
  ,
  'move_buf'
);

$dest = [];
move_char($dest, '#', 0x07, 5);
$str = join('', map { chr($_ & 0xff) } @{ $dest } );
ok (
  length($str) == 5
    &&
  ($dest->[4] & 0xff) eq ord '#'
    &&
  ($dest->[4] >> 8) == 0x07
  ,
  'move_char'
);

$dest = [];
move_str($dest, 'String', 0x70);
$str = join('', map { chr($_ & 0xff) } @{ $dest } );
ok (
  length($str) == 6
    &&
  ($dest->[0] & 0xff) == ord 'S'
    &&
  ($dest->[0] >> 8) == 0x70
  ,
  'move_str'
);

done_testing;
