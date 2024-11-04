use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
  use_ok 'TV::Objects::Const', qw( CC_NOT_FOUND );
}

is( CC_NOT_FOUND, -1, 'CC_NOT_FOUND is -1' );

done_testing();
