use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

BEGIN {
  require_ok 'fields';
  use_ok 'TV::toolkit';
}

{
  package Point;
  use fields qw( x y );
  use subs qw( x );
  sub new {
    my ( $self, %args ) = @_;
    $self      = fields::new( $self ) unless ref $self;
    $self->{x} = $args{x};
    $self->{y} = $args{y};
    return $self;
  }
  sub x {
    $_[0]->{x} = $_[1] if @_ > 2;
    $_[0]->{x};
  }
  $INC{"Point.pm"} = 1;
}

{
  package Point3D;
  use base 'Point';
  use fields 'z';
  sub new {
    my ( $self, %args ) = @_;
    $self = fields::new( $self ) unless ref $self;
    $self->SUPER::new( %args );
    $self->{z} = $args{z};
    return $self;
  }
  $INC{"Point3D.pm"} = 1;
}

is $TV::toolkit::name, 'fields', 'Toolkit is fields';
ok TV::toolkit::is_fields(), 'TV::toolkit::fields is set to true';

subtest 'Slots' => sub {
  is_deeply(
    [ TV::toolkit::all_slots( 'Point' ) ], 
    [
      { name => 'x', initializer => { is => 'bare', init_arg => 'x' } },
      { name => 'y', initializer => { is => 'rw',   init_arg => 'y' } },
    ], 
    'Point->all_slots' 
  );
  is_deeply(
    [ TV::toolkit::all_slots( 'Point3D' ) ], 
    [
      { name => 'x', initializer => { is => 'bare', init_arg => 'x' } },
      { name => 'y', initializer => { is => 'rw',   init_arg => 'y' } },
      { name => 'z', initializer => { is => 'rw',   init_arg => 'z' } },
    ], 
    'Point3D->all_slots'
  );
  is_deeply(
    [ TV::toolkit::slots( 'Point' ) ],
    [
      { name => 'x', initializer => { is => 'bare', init_arg => 'x' } },
      { name => 'y', initializer => { is => 'rw',   init_arg => 'y' } },
    ], 
    'Point->slots'
  );
  is_deeply(
    [ TV::toolkit::slots( 'Point3D' ) ], 
    [
      { name => 'z', initializer => { is => 'rw', init_arg => 'z' } },
    ],
    'Point3D->slots'
  );
  ok(  TV::toolkit::has_slot( 'Point', 'x' ), 'Point has an attribute x' );
  ok( !TV::toolkit::has_slot( 'Point', 'z' ), 'Point has no attribute z' );
  is_deeply(
    TV::toolkit::get_slot( 'Point3D', 'x' ),
    { name => 'x', initializer => { is => 'bare', init_arg => 'x' } },
    'get_slot returns correct meta for x'
  );
  is_deeply(
    TV::toolkit::get_slot( 'Point3D', 'z' ),
    { name => 'z', initializer => { is => 'rw', init_arg => 'z' } },
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
  can_ok( $point, 'x' );
  ok( !Point->can( 'y' ), "!Point->can('y')" );
  lives_ok { 
    use warnings FATAL => 'all';
    TV::toolkit::install_slots( 'Point' );
  } "install_slots( 'Point' )";
  can_ok( $point, qw( x y ) );

  ok( !Point3D->can( 'z' ), "!Point3D->can('z')" );
  lives_ok {
    use warnings FATAL => 'all';
    TV::toolkit::install_slots( 'Point3D' );
  } "install_slots( 'Point3D' )";
  $point = Point3D->new( x => 1, y => 2, z => 3 );
  can_ok( $point, qw( x y z ) );
  ok( !Point->can( 'z' ), "!Point->can('z')" );
};

done_testing;
