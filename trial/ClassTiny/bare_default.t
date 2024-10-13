BEGIN {
  package Object;

  use strict;
  use warnings;

  use Class::Tiny::Antlers;

  our %FIELDS = ();

  # set values for 'default' at 'bare', because 'bare' is not 'lazy'
  sub BUILD {
    my $self = shift;
    my $class = ref $self;
    $FIELDS{$class} //= do {
      # no warnings 'uninitialized'
      local $SIG{__WARN__} = sub { warn $_[0] if $_[0] !~ /uninitialized/ };
      Class::Tiny::Antlers->get_all_attribute_specs_for( $class );
    };
    foreach ( 
      grep {
          !defined($self->{$_})                           # attr not defined
        && $FIELDS{$class}->{$_}->{is} eq 'bare'          # attr is bare
        && exists($FIELDS{$class}->{$_}->{default})       # attr has default
      } keys %{$FIELDS{$class}}
    ) {
      $self->{$_} = ref($FIELDS{$class}->{$_}->{default}) eq 'CODE' 
        ? $FIELDS{$class}->{$_}->{default}->()            # default => sub { }
        : $FIELDS{$class}->{$_}->{default}                # default => ...
    }
  }

  $INC{"Object.pm"} = 1;
}

BEGIN {
  package Point;

  use strict;
  use warnings;

  use Class::Tiny::Antlers;

  extends 'Object';

  has x => ( is => 'bare', default => 0 );
  has y => ( is => 'bare', default => 0 );

  sub x {
    my $self = shift; 
    $self->{x} = shift if @_;
    return $self->{x};
  }

  sub y {
    my $self = shift; 
    $self->{y} = shift if @_;
    return $self->{y};
  }

  $INC{"Point.pm"} = 1;
}

package main;

use Test::More;
use Test::Exception;

use Point;

my $pt;

subtest 'pt(0,0)' => sub {
  lives_ok { $pt = Point->new() };
  is( $pt->x, 0 );
  is( $pt->y, 0 );
};

subtest 'pt(1,2)' => sub {
  lives_ok { $pt = Point->new( x => 1, y => 2 ) };
  is( $pt->x, 1 );
  is( $pt->y, 2 );
};

subtest 'pt(2,3)' => sub {
  lives_ok { $pt->x(2); $pt->y(3) };
  is( $pt->x, 2 );
  is( $pt->y, 3 );
};

done_testing;
