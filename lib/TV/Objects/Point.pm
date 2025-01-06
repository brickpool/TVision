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
  new_TPoint
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use if STRICT => 'Hash::Util';
use Scalar::Util qw(
  blessed
  looks_like_number
);

sub TPoint() { __PACKAGE__ }
sub new_TPoint { __PACKAGE__->from(@_) }

# declare attributes
our %HAS; BEGIN {
  %HAS = ( 
    x => sub { 0 },
    y => sub { 0 },
  );
}

sub new {    # \$obj (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  assert ( keys( %args ) % 2 == 0 );
  assert ( grep( looks_like_number( $_ ), values( %args ) ) == keys( %args ) );
  my $self = {
    x => $args{x} || $HAS{x}->(),
    y => $args{y} || $HAS{y}->(),
  };
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
} #/ sub new

sub from {    # $obj ($x, $y)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 2 );
  return $class->new( x => $_[0], y => $_[1] );
}

sub clone {    # $p ($self)
  my $self = shift;
  assert ( blessed $self );
  my $class = ref $self || $self;
  return $class->new( %$self );
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

my $mk_accessors = sub {
  my $pkg = shift;
  no strict 'refs';
  my %HAS = %{"${pkg}::HAS"};
  for my $field ( keys %HAS ) {
    my $full_name = "${pkg}::$field";
    *$full_name = sub {
      assert( blessed $_[0] );
      if ( @_ > 1 ) {
        assert( looks_like_number $_[1] );
        $_[0]->{$field} = $_[1];
      }
      $_[0]->{$field};
    };
  } #/ for my $field ( keys %HAS)
}; #/ $mk_accessors = sub

__PACKAGE__->$mk_accessors();

1
