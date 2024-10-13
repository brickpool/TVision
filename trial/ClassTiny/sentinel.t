BEGIN {
  package Point;

  use strict;
  use warnings;

  use Class::Tiny::Antlers;
  use Sentinel;

  has x => ( is => 'bare' );
  has y => ( is => 'bare' );

  sub x :lvalue {
    my $self = shift; 
    sentinel
      get => sub {
        return $self->{x}
      }, 
      set => sub {
        $self->{x} = shift;
      }
  }

  sub y :lvalue {
    my $self = shift;
    sentinel
      get => sub {
        return $self->{y}
      }, 
      set => sub {
        $self->{y} = shift;
      }
  }

  $INC{"Point.pm"} = 1;
}

package main;

use Test::More;
use Test::Exception;

use Point;

my $pt;

subtest 'pt(1,2)' => sub {
  lives_ok { $pt = Point->new( x => 1, y => 2 ) };
  is( $pt->x, 1 );
  is( $pt->y, 2 );
};

subtest 'pt(2,3)' => sub {
  lives_ok { 
    $pt->x = 2;
    $pt->y++;
  };
  is( $pt->x, 2 );
  is( $pt->y, 3 );
};

done_testing;
