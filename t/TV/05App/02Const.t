use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
  use_ok 'TV::App::Const', qw( 
    :cpXXXX
    :hcXXXX
    :apXXXX
  );
}

is( cpBackground, "\x01", 'cpBackground is "\x01"' );
is( hcNew,        0xff01, 'hcNew is 0xff01' );
is( apColor,      0,      'apColor is 0' );

done_testing();
