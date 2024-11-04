use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
  use_ok 'TV::Const', qw( 
    EVENT_Q_SIZE
    MAX_FIND_STR_LEN
    MAX_REPLACE_STR_LEN
    MAX_COLLECTION_SIZE
  );
}

is( EVENT_Q_SIZE,        16, 'EVENT_Q_SIZE is 16' );
is( MAX_FIND_STR_LEN,    80, 'MAX_FIND_STR_LEN is 80' );
is( MAX_REPLACE_STR_LEN, 80, 'MAX_REPLACE_STR_LEN is 80' );

is( 
  MAX_COLLECTION_SIZE,
  int( ( ~0 - 16 ) / length( pack( 'P', 0 ) ) ),
  'MAX_COLLECTION_SIZE is calculated correctly' 
);

done_testing;
