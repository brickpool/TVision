=pod

=head1 NAME

TV::Objects::Rect - defines the class TRect

=head1 DECRIPTION

In this Perl module, the I<TRect> class is created, which contains the same 
methods as the Borland C++ class. 

=head2 Methods

The methods I<move>, I<grow>, I<intersect>, I<union>, I<contains>, I<equal>, 
I<not_equal> and I<isEmpty> are implemented to provide the same behavior as in 
the original code.

=cut

package TV::Objects::Rect;

use strict;
use warnings;

use List::Util qw(min max);
use TV::Objects::Point;

use Exporter 'import';
our @EXPORT = qw(
  TRect
);

use Devel::StrictMode;
use if STRICT => 'Hash::Util';
use Sentinel;

sub TRect() { __PACKAGE__ }

# This method creates a new I<TRect> object. It accepts a variable number of 
# arguments:
#
# If four arguments I<(ax, ay, bx, by)> are provided, it creates two I<TPoint> 
# objects for points I<a> and I<b> with the specified coordinates.
#
# If two arguments I<(p1, p2)> are provided, it sets points I<a> and I<b> to the
# provided I<TPoint> objects.
#
# If no or any other number of arguments are provided, it initializes points 
# I<a> and I<b> with new I<TPoint> objects with default values.
sub new {    # $obj (%args)
  my ( $class, %args ) = @_;
  my $self = bless {}, $class;
  if ( keys(%args) == 4 ) {
    $self->{a} = TPoint->new( x => $args{ax}, y => $args{ay} );
    $self->{b} = TPoint->new( x => $args{bx}, y => $args{by} );
  }
  elsif ( keys(%args) == 2 ) {
    $self->{a} = $args{p1};
    $self->{b} = $args{p2};
  }
  $self->{a} ||= TPoint->new();
  $self->{b} ||= TPoint->new();
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
} #/ sub new

sub clone {    # $p ($self)
  my $self = shift;
  my $clone = {
    a => $self->{a}->clone(),
    b => $self->{b}->clone(),
  };
  bless $clone, ref $self;
  Hash::Util::lock_keys( %$clone ) if STRICT;
  return $clone;
}

sub move {    # void ($aDX, $aDY)
  my ( $self, $aDX, $aDY ) = @_;
  $self->{a}{x} += $aDX;
  $self->{a}{y} += $aDY;
  $self->{b}{x} += $aDX;
  $self->{b}{y} += $aDY;
  return;
}

sub grow {    # void ($aDX, $aDY)
  my ( $self, $aDX, $aDY ) = @_;
  $self->{a}{x} -= $aDX;
  $self->{a}{y} -= $aDY;
  $self->{b}{x} += $aDX;
  $self->{b}{y} += $aDY;
  return;
}

sub intersect {    # void ($r)
  my ( $self, $r ) = @_;
  $self->{a}{x} = max( $self->{a}{x}, $r->{a}{x} );
  $self->{a}{y} = max( $self->{a}{y}, $r->{a}{y} );
  $self->{b}{x} = min( $self->{b}{x}, $r->{b}{x} );
  $self->{b}{y} = min( $self->{b}{y}, $r->{b}{y} );
  return;
}

sub Union {    # void ($r)
  my ( $self, $r ) = @_;
  $self->{a}{x} = min( $self->{a}{x}, $r->{a}{x} );
  $self->{a}{y} = min( $self->{a}{y}, $r->{a}{y} );
  $self->{b}{x} = max( $self->{b}{x}, $r->{b}{x} );
  $self->{b}{y} = max( $self->{b}{y}, $r->{b}{y} );
  return;
}

sub contains {    # $bool ($p)
  my ( $self, $p ) = @_;
  return
       $p->{x} >= $self->{a}{x}
    && $p->{x} <  $self->{b}{x}
    && $p->{y} >= $self->{a}{y}
    && $p->{y} <  $self->{b}{y};
}

sub equal {    # $bool ($r)
  my ( $self, $r ) = @_;
  return
       $self->{a}{x} == $r->{a}{x}
    && $self->{a}{y} == $r->{a}{y}
    && $self->{b}{x} == $r->{b}{x}
    && $self->{b}{y} == $r->{b}{y};
}

sub not_equal {    # $bool ($r)
  my ( $self, $r ) = @_;
  return !$self->equal( $r );
}

sub isEmpty {    # $bool ($self)
  my ( $self ) = @_;
  return $self->{a}{x} >= $self->{b}{x} 
      || $self->{a}{y} >= $self->{b}{y};
}

use overload
  '==' => \&equal,
  '!=' => \&not_equal,
  fallback => 1;

sub a :lvalue {    # $p (| $value)
  my $self = shift;
  if ( defined $_[0] ) {
    return $self->{a} = $_[0];
  }
  sentinel
    get => sub { return $self->{a} },
    set => sub { $self->{a} = $_[0] };
}

sub b :lvalue {    # $p (| $value)
  my $self = shift;
  if ( defined $_[0] ) {
    return $self->{b} = $_[0];
  }
  sentinel
    get => sub { return $self->{b} },
    set => sub { $self->{b} = $_[0] };
}

1
