use 5.014;
use warnings;

BEGIN {
  print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
  $| = 1;
}

use Test::More tests => 10;

BEGIN {
  use_ok 'TurboVision::Drivers::Const';
  use_ok 'TurboVision::Drivers::Utility';
}

use TurboVision::Drivers::Const qw( :kbXXXX );
use TurboVision::Drivers::Utility qw( :util );

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

done_testing;
