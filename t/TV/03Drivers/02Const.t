=pod

=head1 DECRIPTION

In this test plan, we use L<Test::More> to check the values of the selected 
constants. The tests ensure that the constants have the expected values. The 
results of the tests are compared with the expected values and the tests issue 
corresponding messages.

=cut

use strict;
use warnings;

use Test::More tests => 19;

BEGIN {
  use_ok 'TV::Drivers::Const', qw( 
    EVENT_Q_SIZE
    MAX_FIND_STR_LEN
    MAX_REPLACE_STR_LEN
    :evXXXX
    :mbXXXX
    :meXXXX
  );
}

is( EVENT_Q_SIZE,        16, 'EVENT_Q_SIZE is 16' );
is( MAX_FIND_STR_LEN,    80, 'MAX_FIND_STR_LEN is 80' );
is( MAX_REPLACE_STR_LEN, 80, 'MAX_REPLACE_STR_LEN is 80' );

is( EV_MOUSE_DOWN,   0x0001, 'EV_MOUSE_DOWN is 0x0001' );
is( EV_MOUSE_UP,     0x0002, 'EV_MOUSE_UP is 0x0002' );
is( EV_MOUSE_MOVE,   0x0004, 'EV_MOUSE_MOVE is 0x0004' );
is( EV_MOUSE_AUTO,   0x0008, 'EV_MOUSE_AUTO is 0x0008' );
is( EV_KEY_DOWN,     0x0010, 'EV_KEY_DOWN is 0x0010' );
is( EV_COMMAND,      0x0100, 'EV_COMMAND is 0x0100' );
is( EV_BROADCAST,    0x0200, 'EV_BROADCAST is 0x0200' );
is( EV_NOTHING,      0x0000, 'EV_NOTHING is 0x0000' );
is( EV_MOUSE,        0x000f, 'EV_MOUSE is 0x000f' );
is( EV_KEYBOARD,     0x0010, 'EV_KEYBOARD is 0x0010' );
is( EV_MESSAGE,      0xFF00, 'EV_MESSAGE is 0xFF00' );

is( MB_LEFT_BUTTON,  0x01,   'MB_LEFT_BUTTON is 0x01' );
is( MB_RIGHT_BUTTON, 0x02,   'MB_RIGHT_BUTTON is 0x02' );

is( ME_MOUSE_MOVED,  0x01,   'ME_MOUSE_MOVED is 0x01' );
is( ME_DOUBLE_CLICK, 0x02,   'ME_DOUBLE_CLICK is 0x02' );

done_testing;
