use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN{
  unless ( eval { require Class::Tiny } ) {
    plan skip_all => 'Test irrelevant without Class::Tiny';
  }
  else {
    plan tests => 10;
  }
  use_ok 'Class::Tiny';
  use_ok 'TV::Objects::Object';
}

BEGIN {
  package Derived;
  require TV::Objects::Object;
  use base 'TV::Objects::Object';
  use fields qw(
    x y
  );
  __PACKAGE__->mk_accessors;
  $INC{"Derived.pm"} = 1;
}

use_ok 'Derived';

# Test new method
my $obj = TObject->new();
isa_ok( $obj, TObject, 'new() creates an object of correct class' );

# Test shutDown method
can_ok( TObject, 'shutDown' );
lives_ok { $obj->shutDown() } 'shutDown() does not throw an exception';

$obj = Derived->new();
isa_ok( $obj, 'Class::Tiny::Object' );

can_ok( $obj, 'x' );
lives_ok { $obj->x() } 'x works correctly';
lives_ok { $obj->y( 1 ) } 'y works correctly';

done_testing();
