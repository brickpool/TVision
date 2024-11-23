use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
  use_ok 'TV::App::Const', qw( cpBackground );
}

is( cpBackground, "\x01", 'cpBackground is "\x01"' );

done_testing();
