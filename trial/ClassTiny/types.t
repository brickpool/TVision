BEGIN {
  package Devel::Assert::More;

  use strict;
  use warnings;
  
  use Exporter 'import';

  our @EXPORT_OK = qw(
    assert_Object
    assert_Int
  );

  use Carp qw( croak );
  use Type::Nano qw( 
    Object
    Int
  );

  $Carp::CarpInternal{ (__PACKAGE__) }++;

  sub assert_Object($) {
    Object->check($_[0]) 
      or croak(Object->get_message($_[0]));
    $_[0];
  }

  sub assert_Int($) {
    Int->check($_[0]) 
      or croak(Int->get_message($_[0]));
    $_[0];
  }

  $INC{"Devel/Assert/More.pm"} = 1;
}

BEGIN {
  package Point;

  use strict;
  use warnings;

  use Class::Tiny::Antlers;
  use Devel::Assert 'on';
  use Devel::Assert::More qw( /^assert/ );
  use Type::Nano qw( Int );

  has x => ( is => 'rw', isa => Int, default => 0 );
  has y => ( is => 'rw', isa => Int, default => 0 );

  sub assign {
    assert( @_ == 3 );
    my $self = assert_Object shift;
    $self->{x} = assert_Int(shift);
    $self->{y} = assert_Int(shift);
    return;
  }

  $INC{"Point.pm"} = 1;
}

package main;

use Test::More;
use Test::Exception;

use Point;
my $pt;

lives_ok { 
  $pt = Point->new();
  is( $pt->x, 0 );
  is( $pt->y, 0 );
} 'pt(0,0)';

lives_ok { 
  $pt = Point->new( x => 1, y => 2 );
  is( $pt->x, 1 );
  is( $pt->y, 2 );
} 'pt(1,2)';

lives_ok { 
  $pt->assign(2, 3);
  is( $pt->x, 2 );
  is( $pt->y, 3 );
} 'pt(2,3)';

subtest 'Type check' => sub {
  throws_ok {
    Point->new(
      x => 'x', 
      y => 'y',
    ) 
  } qr/Int/;
  throws_ok { $pt->assign()         } qr/ == 3/;
  throws_ok { Point->assign(1, 2)   } qr/Object/;
  throws_ok { $pt->assign('a', 'b') } qr/Int/;
  throws_ok { $pt->x('string')      } qr/string/;
  throws_ok { $pt->y(undef)         } qr/undef/i;
  is( $pt->x, 2 );
  is( $pt->y, 3 );
};

done_testing;
