BEGIN {
  package Point;

  use strict;
  use warnings;

  use Class::Tiny::Antlers;

  has x => ( is => 'bare', default => 0 );
  has y => ( is => 'bare', default => sub { 0 } );

  my $FIELDS;

  sub BUILD {
    my $self = shift;
    my $class = ref $self;
    $FIELDS ||= Class::Tiny::Antlers->get_all_attribute_specs_for( $class );
    foreach (
      grep {
          !defined($self->{$_})                           # attr not defined
        && $FIELDS->{$_}->{is} eq 'bare'                  # attr is bare
        && exists($FIELDS->{$_}->{default})               # attr has default
      } keys %$FIELDS
    ) {
      $self->{$_} = ref($FIELDS->{$_}->{default}) eq 'CODE'
        ? $FIELDS->{$_}->{default}->()                    # default => sub { }
        : $FIELDS->{$_}->{default}                        # default => ...
    }
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

package main;

use Test::More;
use Test::Exception;

use Point;

my $pt;

subtest "use warnings FATAL => 'uninitialized'" => sub {
  local $SIG{__WARN__} = sub { die if $_[0] =~ /uninitialized/ };
  dies_ok { $pt = Point->new() };
  is( $pt, undef );
};

subtest "no warnings 'uninitialized'" => sub {
  local $SIG{__WARN__} = sub { warn $_[0] if $_[0] !~ /uninitialized/ };
  lives_ok { $pt = Point->new() };
  is( $pt->x, 0 );
  is( $pt->y, 0 );
};

subtest "new" => sub {
  lives_ok { $pt = Point->new( x => 1, y => 2 ) };
  is( $pt->x, 1 );
  is( $pt->y, 2 );
};

subtest "assign" => sub {
  lives_ok { $pt->x(2); $pt->y(3) };
  is( $pt->x, 2 );
  is( $pt->y, 3 );
};

done_testing;
