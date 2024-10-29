use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

BEGIN {
  use_ok "TV::Objects::Object";
}

# Test TObject function
is( TObject, 'TV::Objects::Object', 'TObject returns correct package name' );

# Test new method
my $obj = TObject->new();
isa_ok( $obj, TObject, 'new() creates an object of correct class' );

# Test shutDown method
can_ok( TObject, 'shutDown' );

# Test shutDown method with exception
lives_ok { $obj->shutDown() } 'shutDown() does not throw an exception';

# Test DESTROY method
lives_ok { $obj->DESTROY() } 'DESTROY() method called without errors';

# Test destroy class method
$obj = TObject->new();
lives_ok {
  TObject->destroy( $obj )
} 'destroy() does not throw an exception';
ok( !defined $obj, 'destroy() undefines the object' );

done_testing();
