use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

BEGIN {
  require_ok 'fields';
  use_ok 'TV::toolkit';
}

BEGIN {
  package Point;
  use TV::toolkit;
  slots x => ( is => 'bare' );
  slots y => ( is => 'rw' );
  sub x {
    $_[0]->{x} = $_[1] if @_ > 2;
    $_[0]->{x};
  }
  no TV::toolkit;
  $INC{"Point.pm"} = 1;
}

BEGIN {
  package Point3D;
  use TV::toolkit;
  extends 'Point';
  slots z => ( is => 'rw' );
  $INC{"Point3D.pm"} = 1;
}

is $TV::toolkit::name, 'fields', 'Toolkit is fields';
ok TV::toolkit::is_fields(), 'TV::toolkit::fields is set to true';

subtest 'Slots' => sub {
  is_deeply(
    [ TV::toolkit::all_slots( 'Point' ) ], 
    [
      { name => 'x', initializer => 1 },
      { name => 'y', initializer => 2 },
    ], 
    'Point->all_slots' 
  );
  is_deeply(
    [ TV::toolkit::all_slots( 'Point3D' ) ], 
    [
      { name => 'x', initializer => 1 },
      { name => 'y', initializer => 2 },
      { name => 'z', initializer => 3 },
    ], 
    'Point3D->all_slots'
  );
  is_deeply(
    [ TV::toolkit::slots( 'Point' ) ],
    [
      { name => 'x', initializer => 1 },
      { name => 'y', initializer => 2 },
    ], 
    'Point->slots'
  );
  is_deeply(
    [ TV::toolkit::slots( 'Point3D' ) ], 
    [
      { name => 'z', initializer => 3 },
    ],
    'Point3D->slots'
  );
  ok(  TV::toolkit::has_slot( 'Point', 'x' ), 'Point has an attribute x' );
  ok( !TV::toolkit::has_slot( 'Point', 'z' ), 'Point has no attribute z' );
  is_deeply(
    TV::toolkit::get_slot( 'Point3D', 'x' ),
    { name => 'x', initializer => 1 },
    'get_slot returns correct meta for x'
  );
  is_deeply(
    TV::toolkit::get_slot( 'Point3D', 'z' ),
    { name => 'z', initializer => 3 },
    'get_slot returns correct meta for z'
  );
  is( 
    TV::toolkit::get_slot( 'Point', 'z' ), 
    undef, 
    'get_slot returns undef for unknown attribute'
  );
};

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

subtest 'install slots' => sub {
  my $point = Point->new( x => 2, y => 3 );
  can_ok( $point, qw( x y ) );
  ok( !Point->can( 'z' ), "!Point->can('z')" );

  $point = Point3D->new( x => 1, y => 2, z => 3 );
  can_ok( $point, qw( x y z ) );
};

done_testing;
