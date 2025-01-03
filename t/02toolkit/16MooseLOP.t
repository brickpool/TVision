use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Dumper;

BEGIN {
  unless ( eval { require Moose } ) {
    plan skip_all => 'Test irrelevant without Moose';
  }
  else {
    plan tests => 16;
  }
  use_ok 'TV::toolkit::LOP::Moose';
}

BEGIN {
  package toolkit;
  use strict;
  use warnings;

  require TV::toolkit::LOP::Moose;

  sub import {
    my $caller = caller();
    Moose::LOP->new( $caller )
      ->warnings_strict()
      ->have_accessors( 'slot' );

    Moose::LOP->init( __PACKAGE__ )
      ->import_methods($caller, qw( extends ));
  }

  sub extends {
    Moose::LOP->init( caller() )->extend_class( @_ );
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
  no strict 'refs';
  no warnings 'once';
  use_ok 'Point';
  my ( %accessors, $next );
  while ( my ( $name, $symbol ) = each %{'Point::'} ) {
    next unless *{$symbol}{CODE};    # print subs only
    next if $symbol !~ /::[xy]$/;    # do not use imported subs
    $accessors{$name} = ++$next;
  }
  is_deeply(
    [ sort keys %accessors ],
    [ qw( x y ) ],
    '%Point::* is equal to Moose generated accessors'
  );
  is_deeply(
    [ sort keys %{ Moose::LOP->init('Point')->get_attributes() } ],
    [ qw( x y ) ],
    'get_attributes() for Point works correctly'
  );
  $_ = Dumper( Moose::LOP->init('Point')->get_attributes() );
  s/\$VAR1/*{'Point::'}{CODE}/;
  note $_;
}

{
  no strict 'refs';
  no warnings 'once';
  use_ok 'Point3D';
  my ( %accessors, $next );
  while ( my ( $name, $symbol ) = each %{'Point3D::'} ) {
    next unless *{$symbol}{CODE};
    next if $symbol !~ /::[xyz]$/;
    $accessors{$name} = ++$next;
  }
  is_deeply(
    [ sort keys %accessors ],
    [ qw( z ) ],
    '%Point3D::* is equal to Moose generated accessors'
  );
  is_deeply(
    [ sort keys %{ Moose::LOP->init('Point3D')->get_attributes() } ],
    [ qw( z ) ],
    'get_attributes() for Point3D works correctly'
  );
  $_ = Dumper( Moose::LOP->init('Point3D')->get_attributes() );
  s/\$VAR1/*{'Point3D::*'}{CODE}/;
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
    'keys %$point is equal to Moose'
  );
}

done_testing();
