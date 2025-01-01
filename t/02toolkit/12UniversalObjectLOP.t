use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Dumper;

BEGIN {
  unless ( eval { require UNIVERSAL::Object } ) {
    plan skip_all => 'Test irrelevant without Universal::Object';
  }
  else {
    plan tests => 16;
  }
  use_ok 'TV::toolkit::LOP::UNIVERSAL::Object';
}

BEGIN {
  package toolkit;
  use strict;
  use warnings;

  require TV::toolkit::LOP::UNIVERSAL::Object;

  sub import {
    my $caller = caller();
    UNIVERSAL::Object::LOP->new($caller)
      ->warnings_strict()
      ->have_accessors('slot');

    UNIVERSAL::Object::LOP->init( __PACKAGE__ )
      ->import_methods($caller, qw( extends ));
  }

  sub extends {
    my $caller = caller();
    UNIVERSAL::Object::LOP->init( $caller )
      ->extend_class( @_ );
  }

  $INC{"toolkit.pm"} = 1;
}

use_ok 'toolkit';

BEGIN {
  package Point;
  use toolkit;

  slot x => ( default => sub { 0 } );
  slot y => ( is => 'rw', default => 0 );

  $INC{"Point.pm"} = 1;
}

BEGIN { 
  package Point3D;
  use toolkit;

  extends 'Point';

  slot z => ( is => 'ro', default => sub { 0 } );

  $INC{"Point3D.pm"} = 1;
}

{
  no warnings 'once';
  use_ok 'Point';
  is_deeply(
    [ sort keys %Point::HAS ],
    [ qw( x y ) ],
    'keys %Point::HAS is equal to fields'
  );
  is_deeply(
    [ sort keys %{ UNIVERSAL::Object::LOP->init('Point')->get_attributes() } ],
    [ qw( x y ) ],
    'get_attributes() for Point3D works correctly'
  );
  $_ = Dumper { Point->SLOTS() };
  s/\$VAR1/*{'Point::HAS'}{HASH}/;
  note $_;
}

{
  no warnings 'once';
  use_ok 'Point3D';
  is_deeply(
    [ sort keys %Point3D::HAS ],
    [ qw( x y z ) ],
    'keys %Point3D::HAS is equal to fields'
  );
  is_deeply(
    [ keys %{ UNIVERSAL::Object::LOP->init('Point3D')->get_attributes() } ],
    [ qw( z ) ],
    'get_attributes() for Point works correctly'
  );
  $_ = Dumper { Point3D->SLOTS() };
  s/\$VAR1/*{'Point3D::HAS'}{HASH}/;
  note $_;
}

{
  my $point = Point->new( x => 5, y => 10 );
  is( $point->x, 5,  "Point->new sets x correctly" );
  is( $point->y, 10, "Point->new sets y correctly" );
}

{
  my $point = Point3D->new( z => 4 );
  is( $point->x, 0, "Point3D->new sets x correctly" );
  is( $point->y, 0, "Point3D->new sets y correctly" );
  is( $point->z, 4, "Point3D->new sets z correctly" );

  isa_ok( $point, 'UNIVERSAL::Object' );
  dies_ok { $point->z(5) } 'Access to attribute z works correctly';

  is_deeply(
    [ sort keys %$point ],
    [ qw( x y z ) ],
    'keys %$point is equal to fields'
  );
}

note 'Class::XSAccessor: ', UNIVERSAL::Object::LOP::XS ? 1 : 0;

done_testing();
