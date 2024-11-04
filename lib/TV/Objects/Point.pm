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
use if STRICT => 'Hash::Util';
use Sentinel;

sub TPoint() { __PACKAGE__ }

sub new {    # $obj (%args)
  my ( $class, %args ) = @_;
  my $self = {
    x => $args{x} // 0,
    y => $args{y} // 0,
  };
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
}

sub clone {    # $p ($self)
  my $self = shift;
  my $clone = bless { %$self }, ref $self;
  Hash::Util::lock_keys( %$clone ) if STRICT;
  return $clone;
}

sub add {    # $p ($one, $two)
  my ( $one, $two ) = @_;
  return TPoint->new( x => $one->{x} + $two->{x}, y => $one->{y} + $two->{y} );
}

sub subtract {    # $p ($one, $two)
  my ( $one, $two ) = @_;
  return TPoint->new( x => $one->{x} - $two->{x}, y => $two->{y} - $two->{y} );
}

sub equal {    # $bool ($one, $two)
  my ( $one, $two ) = @_;
  return $one->{x} == $two->{x} && $one->{y} == $two->{y};
}

sub not_equal {    # $bool ($one, $two)
  my ( $one, $two ) = @_;
  return !equal( $one, $two );
}

sub add_assign {    # $self ($adder)
  my ( $self, $adder ) = @_;
  $self->{x} += $adder->{x};
  $self->{y} += $adder->{y};
  return $self;
}

sub subtract_assign {    # $self ($subber)
  my ( $self, $subber ) = @_;
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

sub x :lvalue {    # $x (| $value)
  my $self = shift;
  if ( defined $_[0] ) {
    return $self->{x} = $_[0];
  }
  sentinel
    get => sub { return $self->{x} },
    set => sub { $self->{x} = $_[0] };
}

sub y :lvalue {    # $y (| $value)
  my $self = shift;
  if ( defined $_[0] ) {
    return $self->{y} = $_[0];
  }
  sentinel
    get => sub { return $self->{y} },
    set => sub { $self->{y} = $_[0] };
}

1
