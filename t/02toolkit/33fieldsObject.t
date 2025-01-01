use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

BEGIN {
  require_ok 'fields';
  use_ok 'TV::toolkit';
}

ok( TV::toolkit::is_fields(), 'is fields based toolkit' );

BEGIN {
  package MyObject;
  use TV::toolkit;
  slots x => ();
  slots y => ();
  $INC{"MyObject.pm"} = 1;
}

use_ok 'MyObject';

# Test new method
my $obj = MyObject->new();
isa_ok( $obj, 'MyObject', 'new() creates an object of correct class' );
can_ok( $obj, 'DESTROY' );

# Test accessors
can_ok( $obj, qw( x y ) );
lives_ok { $obj->x() } 'x works correctly';
lives_ok { $obj->y( 1 ) } 'y works correctly';

done_testing();
