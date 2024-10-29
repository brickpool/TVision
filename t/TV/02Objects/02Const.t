use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
  use_ok 'TV::Objects::Const', qw( 
    CC_NOT_FOUND
    MAX_COLLECTION_SIZE
  );
}


is( CC_NOT_FOUND, -1, 'CC_NOT_FOUND is -1' );

is( 
  MAX_COLLECTION_SIZE,
  int( ( ( 2**32 - 1 ) - 16 ) / length( pack( 'P', 0 ) ) ),
  'MAX_COLLECTION_SIZE is calculated correctly' 
);

done_testing();
