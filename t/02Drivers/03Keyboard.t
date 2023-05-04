use 5.014;
use warnings;
use Test::More;

if( $^O ne 'MSWin32' ) {
  plan skip_all => 'Test relevant only for Windows OS';
}
else {
  plan tests => 11;
}

use Scalar::Util qw( blessed );

require_ok 'TurboVision::Drivers::Const';
require_ok 'TurboVision::Drivers::Win32::Keyboard';

use TurboVision::Drivers::Const qw( :kbXXXX );
use TurboVision::Drivers::Win32::Keyboard qw( :kbd );

is(
  ctrl_to_arrow( ord "\cF" ), # Ctrl-F
  KB_END,                     # End
  'ctrl_to_arrow'
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

my $ev;
get_key_event($ev);
ok(
  blessed( $ev ),
  'get_key_event'
);

is(
  get_shift_state(),
  KB_INS_STATE,
  'get_shift_state'
);

done_testing;
