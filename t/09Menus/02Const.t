use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::Menus::Const', qw( :cpXXXX );
}

is( ord( cpMenuView ), 0x02, 'cpMenuView begins with "\x02"' );

done_testing();
