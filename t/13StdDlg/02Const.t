use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::StdDlg::Const', qw( :cmXXXX );
}

is( cmFileOpen,    1001, 'cmFileFocused is 1001' );
is( cmFileFocused, 102,  'cmFileFocused is 102' );

done_testing();
