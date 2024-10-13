BEGIN {
  package Object;

  use strict;
  use warnings;

  use Class::Tiny::Antlers;

  our %FIELDS = ();

  # disallow setting the attribute on undefined 'init_arg'
  sub BUILDARGS {
    my $class = shift;
    my (%args) = @_;
    $FIELDS{$class} //= do {
      # no warnings 'uninitialized'
      local $SIG{__WARN__} = sub { warn $_[0] if $_[0] !~ /uninitialized/ };
      Class::Tiny::Antlers->get_all_attribute_specs_for( $class );
    };
    delete $args{$_} for grep {                           # delete argument
           exists $args{$_}                               # ..when valid
        && exists $FIELDS{$class}->{$_}->{init_arg}       # ..and init_args
        && ref    $FIELDS{$class}->{$_}->{init_arg}       # ..is \undef
      } keys %{$FIELDS{$class}};
    return { %args };
  }

  $INC{"Object.pm"} = 1;
}

BEGIN {
  package Point;

  use strict;
  use warnings;

  use Class::Tiny::Antlers;

  extends 'Object';

  has x => ( is => 'rw', init_arg => \undef );
  has y => ( is => 'rw' );


  $INC{"Point.pm"} = 1;
}

package main;

use Test::More;
use Test::Exception;

use Point;

my $pt;

subtest 'pt(undef,2)' => sub {
  lives_ok { $pt = Point->new( x => 1, y => 2 ) };
  is( $pt->x, undef );
  is( $pt->y, 2 );
};

subtest 'pt(2,3)' => sub {
  lives_ok { $pt->x(2); $pt->y(3) };
  is( $pt->x, 2 );
  is( $pt->y, 3 );
};

done_testing;
