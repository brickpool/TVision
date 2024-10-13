BEGIN {
  package Point;

  use strict;
  use warnings;

  use Class::Tiny::Antlers;
  use Types::Standard qw( Int );

  { 
    # no warnings 'uninitialized'
    local $SIG{__WARN__} = sub { warn $_[0] if $_[0] !~ /uninitialized/ };
    has x => ( is => 'bare', isa => Int );
    has y => ( is => 'bare', isa => Int );
  }

  sub x {
    my $self = shift; 
    $self->{x} = shift if @_;
    return $self->{x}
  }

  sub y {
    my $self = shift; 
    $self->{y} = shift if @_;
    return $self->{y};
  }

  $INC{"Point.pm"} = 1;
}

BEGIN {
  package Point3D;

  use strict;
  use warnings;

  use Class::Tiny::Antlers;
  use Types::Standard qw( Int );

  has x => ( is => 'rw', isa => Int );
  has y => ( is => 'rw', isa => Int );
  { 
    # no warnings 'uninitialized'
    #local $SIG{__WARN__} = sub { warn $_[0] if $_[0] !~ /uninitialized/ };
    has z => ( is => 'bare', isa => Int );
  }

  sub BUILD {
  }

  sub z {
    my $self = shift; 
    $self->{z} = shift if @_;
    return $self->{z};
  }

  $INC{"Point3D.pm"} = 1;
}

package main;

use Test::More;
use Test::Exception;

use Point;
use Point3D;

my $pt;

dies_ok { 
  $pt = Point->new( x => 'x', y => 'y' );
}, 'dies ok';

lives_ok { 
  $pt = Point->new();
  is( $pt->x, undef );
  is( $pt->y, undef );
}, 'pt(undef, undef)';

lives_ok { 
  $pt = Point->new( x => 1, y => 2 );
  is( $pt->x, 1 );
  is( $pt->y, 2 );
} 'pt(1, 2)';

lives_ok {
  $pt->x( 2 ); $pt->y( 3 );
  is( $pt->x, 2 );
  is( $pt->y, 3 );
} 'pt(2, 3)';

dies_ok {
  $pt = Point3D->new( x => 'x', y => 'y', z => 'z' );
  fail "not died!";
  is( $pt->x, 'x', "x => 'x'" );
  is( $pt->y, 'y', "y => 'y'" );
  is( $pt->z, 'z', "z => 'z'" );
} 'should die';

done_testing;
