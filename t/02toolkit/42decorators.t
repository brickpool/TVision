use strict;
use warnings;

use Test::More tests => 15;
use Test::Exception;

BEGIN {
  package Local::Class;
  BEGIN {
    ::require_ok 'TV::decorators';
    ::lives_ok { TV::decorators->import() } 'TV::decorators->import();';
  }

  sub new {
    bless [], $_[0];
  }

  sub class_method :static {
    my $class = shift;
    ::is $class, __PACKAGE__, '$class is ok';
    return;
  }

  sub instance_method :instance {
    my $self = shift;
    ::is ref $self, __PACKAGE__, '$self is ok';
    return;
  }

  $INC{'Local/Class.pm'} = 1;
}

use_ok 'Local::Class';

my $obj = Local::Class->new();
isa_ok( $obj, 'Local::Class' );

ok( !$obj->can( 'FETCH_CODE_ATTRIBUTES' ), 'cannot FETCH_CODE_ATTRIBUTES' );
ok( !$obj->can( 'MODIFY_CODE_ATTRIBUTES' ), 'cannot MODIFY_CODE_ATTRIBUTES' );

lives_ok { Local::Class->class_method() } ':static works';
throws_ok { Local::Class::class_method( 'Local::Mock' ) } qr/not a subclass/;
throws_ok { Local::Class::class_method() } qr/invoked as a function/;
throws_ok { $obj->class_method() } qr/invoked as an instance/;

lives_ok { $obj->instance_method() } ':instance works';
throws_ok { Local::Class::instance_method() } qr/invoked as a function/;
throws_ok { Local::Class->instance_method() } qr/not invoked as an instance/;

done_testing;
