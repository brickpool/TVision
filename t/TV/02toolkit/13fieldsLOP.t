use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;
use Data::Dumper;

BEGIN {
  use_ok 'TV::toolkit::LOP::Class::Fields';
}

BEGIN {
  package toolkit;
  use strict;
  use warnings;

  use TV::toolkit::LOP::Class::Fields;

  sub import {
    my $caller = caller();
    $_ = Class::Fields::LOP->init($caller)
      ->create_constructor()
      ->warnings_strict()
      ->have_accessors('slot');

    Class::Fields::LOP->init( __PACKAGE__ )
      ->import_methods($caller, qw( extends ));
  }

  sub extends {
    my $caller = caller();
    Class::Fields::LOP->init( $caller )
      ->extend_class( @_ );
  }

  $INC{"toolkit.pm"} = 1;
}

use_ok 'toolkit';

BEGIN {
  package Point;
  use toolkit;

  slot x => ( is => 'rw', default => 1 );
  slot y => ( is => 'rw', default => sub { 2 } );

  $INC{"Point.pm"} = 1;
}

BEGIN { 
  package Point3D;
  use toolkit;

  extends 'Point';

  slot z => ( is => 'ro' );

  $INC{"Point3D.pm"} = 1;
}

{
  no warnings 'once';
  use_ok 'Point';
  is_deeply(
    [ sort keys %Point::FIELDS ],
    [ qw( x y ) ],
    'keys %Point::FIELDS is equal to fields'
  );
  is_deeply(
    Class::Fields::LOP->init('Point')->get_attributes(),
    { x => 1, y => 2 },
    'get_attributes() for Point works correctly'
  );
  $_ = Dumper \%Point::FIELDS;
  s/\$VAR1/*{'Point::FIELDS'}{HASH}/;
  note $_;
}

{
  no warnings 'once';
  use_ok 'Point3D';
  is_deeply(
    [ sort keys %Point3D::FIELDS ],
    [ qw( x y z ) ],
    'keys %Point3D::FIELDS is equal to fields'
  );
  is_deeply(
    Class::Fields::LOP->init('Point3D')->get_attributes(),
    { z => 3 },
    'get_attributes() for Point3D works correctly'
  );
  $_ = Dumper \%Point3D::FIELDS;
  s/\$VAR1/*{'Point3D::FIELDS'}{HASH}/;
  note $_;
}

{
  my $point = Point->new( x => 5, y => 10 );
  is( $point->x, 5,  "Point->new sets x correctly" );
  is( $point->y, 10, "Point->new sets y correctly" );
}

{
  my $point = Point3D->new( z => 4 );
  isa_ok( $point, 'Point' );
  is( $point->x, 1, "Point3D->new sets x correctly" );
  is( $point->y, 2, "Point3D->new sets y correctly" );

  dies_ok { $point->z(3) } 'Access to attribute z works correctly';
  is( $point->z, 4, "Point3D->new sets z correctly" );

  is_deeply(
    [ sort keys %$point ],
    [ qw( x y z ) ],
    'keys %$point is equal to fields'
  );
}

note 'Class::XSAccessor: ', Class::Fields::LOP::XS ? 1 : 0;

done_testing();
