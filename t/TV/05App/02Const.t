use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
  use_ok 'TV::App::Const', qw( CP_BACKGROUND );
}

is( CP_BACKGROUND, "\x01", 'CP_BACKGROUND is "\x01"' );

done_testing();
