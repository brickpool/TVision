=pod

=head1 DECRIPTION

In this test plan, we use L<Test::More> to check the values of the selected 
constants. The tests ensure that the constants have the expected values. The 
results of the tests are compared with the expected values and the tests issue 
corresponding messages.

=cut

use strict;
use warnings;

use Test::More tests => 24;

BEGIN {
  use_ok 'TV::Views::Const', qw( :cmXXXX );
}

is( CM_VALID,       0,   'CM_VALID is 0' );
is( CM_QUIT,        1,   'CM_QUIT is 1' );
is( CM_ERROR,       2,   'CM_ERROR is 2' );
is( CM_MENU,        3,   'CM_MENU is 3' );
is( CM_CLOSE,       4,   'CM_CLOSE is 4' );
is( CM_ZOOM,        5,   'CM_ZOOM is 5' );
is( CM_RESIZE,      6,   'CM_RESIZE is 6' );
is( CM_NEXT,        7,   'CM_NEXT is 7' );
is( CM_PREV,        8,   'CM_PREV is 8' );
is( CM_HELP,        9,   'CM_HELP is 9' );
is( CM_OK,          10,  'CM_OK is 10' );
is( CM_CANCEL,      11,  'CM_CANCEL is 11' );
is( CM_YES,         12,  'CM_YES is 12' );
is( CM_NO,          13,  'CM_NO is 13' );
is( CM_DEFAULT,     14,  'CM_DEFAULT is 14' );
is( CM_NEW,         30,  'CM_NEW is 30' );
is( CM_OPEN,        31,  'CM_OPEN is 31' );
is( CM_SAVE,        32,  'CM_SAVE is 32' );
is( CM_SAVE_AS,     33,  'CM_SAVE_AS is 33' );
is( CM_SAVE_ALL,    34,  'CM_SAVE_ALL is 34' );
is( CM_CH_DIR,      35,  'CM_CH_DIR is 35' );
is( CM_DOS_SHELL,   36,  'CM_DOS_SHELL is 36' );
is( CM_CLOSE_ALL,   37,  'CM_CLOSE_ALL is 37' );

done_testing;
