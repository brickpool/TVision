=pod

=head1 NAME

TV::Objects::Rect - defines the class TRect

=head1 DESCRIPTION

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

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TRect
  new_TRect
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use if STRICT => 'Hash::Util';
use Scalar::Util qw( 
  blessed 
  looks_like_number
  reftype
);

sub TRect() { __PACKAGE__ }
sub new_TRect { __PACKAGE__->from(@_) }

# declare attributes
our %HAS; BEGIN {
  %HAS = ( 
    a => sub { TPoint->new() },
    b => sub { TPoint->new() },
  );
}

# This method accepts a variable number of arguments:
#
# If four arguments I<(ax, ay, bx, by)> are provided, it creates two I<TPoint> 
# objects for points I<a> and I<b> with the specified coordinates.
#
# If two arguments I<(p1, p2)> are provided, it sets points I<a> and I<b> to the
# provided I<TPoint> objects.
#
# If no or any other number of arguments are provided, it initializes points 
# I<a> and I<b> with new I<TPoint> objects with default values.
sub new {    # \$obj (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  assert ( keys( %args ) % 2 == 0 );
  if ( keys( %args ) == 2 ) {
    my @params = qw( p1 p2 );
    assert( grep( ref $args{$_} => @params ) == @params );
    $args{a} = TPoint->new( x => $args{p1}{x}, y => $args{p1}{y} );
    $args{b} = TPoint->new( x => $args{p2}{x}, y => $args{p2}{y} );
    delete @args{@params};
  }
  elsif ( keys( %args ) == 4 ) {
    my @params = qw( ax ay bx by );
    assert( grep( looks_like_number $args{$_} => @params ) == 4 );
    $args{a} = TPoint->new( x => $args{ax}, y => $args{ay} );
    $args{b} = TPoint->new( x => $args{bx}, y => $args{by} );
    delete @args{@params};
  }
  my $self = {
    a => $args{a} || $HAS{a}->(),
    b => $args{b} || $HAS{b}->(),
  };
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
} #/ sub new

sub from {    # $obj ($ax, $ay, $bx, $by)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 4 );
  return $class->new( ax => $_[0], ay => $_[1], bx => $_[2], by => $_[3] );
}

sub clone {    # $p ($self)
  my $self = shift;
  assert ( blessed $self );
  my $class = ref $self || $self;
  return $class->new(
    p1 => $self->{a}->clone(),
    p2 => $self->{b}->clone(),
  );
}

sub dump {    # $str ()
  my $self = shift;
  assert ( blessed $self );
  require Data::Dumper;
  local $Data::Dumper::Sortkeys = 1;
  return Data::Dumper::Dumper $self;
}

sub move {    # void ($aDX, $aDY)
  my ( $self, $aDX, $aDY ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aDX );
  assert ( looks_like_number $aDY );
  $self->{a}{x} += $aDX;
  $self->{a}{y} += $aDY;
  $self->{b}{x} += $aDX;
  $self->{b}{y} += $aDY;
  return;
}

sub grow {    # void ($aDX, $aDY)
  my ( $self, $aDX, $aDY ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aDX );
  assert ( looks_like_number $aDY );
  $self->{a}{x} -= $aDX;
  $self->{a}{y} -= $aDY;
  $self->{b}{x} += $aDX;
  $self->{b}{y} += $aDY;
  return;
}

sub intersect {    # void ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  $self->{a}{x} = max( $self->{a}{x}, $r->{a}{x} );
  $self->{a}{y} = max( $self->{a}{y}, $r->{a}{y} );
  $self->{b}{x} = min( $self->{b}{x}, $r->{b}{x} );
  $self->{b}{y} = min( $self->{b}{y}, $r->{b}{y} );
  return;
}

sub Union {    # void ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  $self->{a}{x} = min( $self->{a}{x}, $r->{a}{x} );
  $self->{a}{y} = min( $self->{a}{y}, $r->{a}{y} );
  $self->{b}{x} = max( $self->{b}{x}, $r->{b}{x} );
  $self->{b}{y} = max( $self->{b}{y}, $r->{b}{y} );
  return;
}

sub contains {    # $bool ($p)
  my ( $self, $p ) = @_;
  assert ( blessed $self );
  assert ( ref $p );
  return
       $p->{x} >= $self->{a}{x}
    && $p->{x} <  $self->{b}{x}
    && $p->{y} >= $self->{a}{y}
    && $p->{y} <  $self->{b}{y};
}

sub equal {    # $bool ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  return
       $self->{a}{x} == $r->{a}{x}
    && $self->{a}{y} == $r->{a}{y}
    && $self->{b}{x} == $r->{b}{x}
    && $self->{b}{y} == $r->{b}{y};
}

sub not_equal {    # $bool ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  return !$self->equal( $r );
}

sub isEmpty {    # $bool ($self)
  my $self = shift;
  assert ( blessed $self );
  return $self->{a}{x} >= $self->{b}{x} 
      || $self->{a}{y} >= $self->{b}{y};
}

use overload
  '==' => \&equal,
  '!=' => \&not_equal,
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
        assert( blessed $_[1] );
        $_[0]->{$field} = $_[1]->clone();
      }
      $_[0]->{$field};
    };
  } #/ for my $field ( keys %HAS)
}; #/ $mk_accessors = sub

__PACKAGE__->$mk_accessors();

1
