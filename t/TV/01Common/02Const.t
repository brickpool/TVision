use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
  use_ok 'TV::Const', qw( 
    maxFindStrLen
    maxReplaceStrLen
  );
}

is( maxFindStrLen,    80, 'maxFindStrLen is 80' );
is( maxReplaceStrLen, 80, 'maxReplaceStrLen is 80' );

done_testing;
