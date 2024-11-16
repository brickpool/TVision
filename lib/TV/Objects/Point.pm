=pod

=head1 NAME

TV::Objects::Point - defines the class TPoint

=cut

package TV::Objects::Point;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TPoint
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use if STRICT => 'Hash::Util';
use Scalar::Util qw(
  blessed
  looks_like_number
);

sub TPoint() { __PACKAGE__ }

our %FIELDS = (
  x => 1,
  y => 1,
);

sub new {    # $obj (%args)
  no warnings 'uninitialized';
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  my $self = {
    x => 0+ $args{x},
    y => 0+ $args{y},
  };
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
}

sub clone {    # $p ($self)
  my $self = shift;
  assert ( blessed $self );
  my $clone = bless { %$self }, ref $self;
  Hash::Util::lock_keys( %$clone ) if STRICT;
  return $clone;
}

sub add {    # $p ($one, $two)
  my ( $one, $two ) = @_;
  assert ( ref $one );
  assert ( ref $two );
  return TPoint->new( x => $one->{x} + $two->{x}, y => $one->{y} + $two->{y} );
}

sub subtract {    # $p ($one, $two)
  my ( $one, $two, $swap ) = @_;
  assert ( ref $one );
  assert ( ref $two );
  assert ( !defined $swap or !ref $swap );
  ( $one, $two ) = ( $two, $one ) if $swap;
  return TPoint->new( x => $one->{x} - $two->{x}, y => $one->{y} - $two->{y} );
}

sub equal {    # $bool ($one, $two)
  my ( $one, $two ) = @_;
  assert ( ref $one );
  assert ( ref $two );
  return $one->{x} == $two->{x} && $one->{y} == $two->{y};
}

sub not_equal {    # $bool ($one, $two)
  my ( $one, $two ) = @_;
  assert ( ref $one );
  assert ( ref $two );
  return !equal( $one, $two );
}

sub add_assign {    # $self ($adder)
  my ( $self, $adder ) = @_;
  assert ( blessed $self );
  assert ( ref $adder );
  $self->{x} += $adder->{x};
  $self->{y} += $adder->{y};
  return $self;
}

sub subtract_assign {    # $self ($subber)
  my ( $self, $subber ) = @_;
  assert ( blessed $self );
  assert ( ref $subber );
  $self->{x} -= $subber->{x};
  $self->{y} -= $subber->{y};
  return $self;
}

use overload
  '+'  => \&add,
  '-'  => \&subtract,
  '==' => \&equal,
  '!=' => \&not_equal,
  '+=' => \&add_assign,
  '-=' => \&subtract_assign,
  fallback => 1;

my $_mk_accessors = sub {
  my $pkg = shift;
  for my $field ( keys %FIELDS ) {
    no strict 'refs';
    my $fullname = "${pkg}::$field";
    *$fullname = sub {
      assert( blessed $_[0] );
      if ( @_ > 1 ) {
        assert( looks_like_number $_[1] );
        $_[0]->{$field} = $_[1];
      }
      $_[0]->{$field};
    };
  } #/ for my $field ( keys %FIELDS)
}; #/ $_mk_accessors = sub

__PACKAGE__->$_mk_accessors();

1
