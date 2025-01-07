use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

BEGIN {
  require_ok 'Moos';
  use_ok 'TV::toolkit';
}

BEGIN {
  package Point;
  use TV::toolkit;
  has x => ( is => 'bare' );
  has y => ( is => 'rw' );
  sub x {
    $#_ ? $_[0]->{x} = $_[1] : $_[0]->{x}
  }
  no TV::toolkit;
  $INC{"Point.pm"} = 1;
}

BEGIN {
  package Point3D;
  use TV::toolkit;
  extends 'Point';
  has z => ( is => 'rw' );
  no TV::toolkit;
  $INC{"Point3D.pm"} = 1;
}

is $TV::toolkit::name, 'Moos', 'Toolkit is Moos';
ok TV::toolkit::is_Moos(), 'TV::toolkit::is_Moos is set to true';

subtest 'Point' => sub {
  my $point = Point->new( x => 2, y => 3 );
  isa_ok( $point, 'Point', 'Object is of class Point' );
  is_deeply( $point, { x => 2, y => 3 }, 'point is set correctly' );
};

subtest 'Point3D' => sub {
  my $point = Point3D->new( x => 1, y => 2, z => 3 );
  isa_ok( $point, 'Point3D', 'Object is of class Point3D' );
  is_deeply( $point, { x => 1, y => 2, z => 3 }, 'point is set correctly' );
};

subtest 'install has' => sub {
  my $point = Point->new( x => 2, y => 3 );
  can_ok( $point, qw( x y ) );
  ok( !Point->can( 'z' ), "!Point->can('z')" );

  $point = Point3D->new( x => 1, y => 2, z => 3 );
  can_ok( $point, qw( x y z ) );
};

done_testing;
