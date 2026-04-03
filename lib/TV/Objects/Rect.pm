package TV::Objects::Rect;
# ABSTRACT: defines the class TRect

use 5.010;
use strict;
use warnings;

use List::Util qw( min max );
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
use PerlX::Assert::PP;
use if STRICT => 'Hash::Util';
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  :is
  :types
);

sub TRect() { __PACKAGE__ }
sub new_TRect { __PACKAGE__->from(@_) }

# public attributes
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
# If two arguments I<(a, b)> are provided, it sets points I<a> and I<b> to the
# provided I<TPoint> objects.
#
# If no or any other number of arguments are provided, it initializes points 
# I<a> and I<b> with new I<TPoint> objects with default values.
sub new {    # \$obj (%args)
  my ( $class, $self );
  if ( @_ < 4 ) {
    state $sig = signature(
      method => 1,
      named  => [],
    );
    ( $class ) = $sig->( @_ );
    $self = {
      a => TPoint->new(),
      b => TPoint->new(),
    };
  }
  elsif ( @_ < 8 ) {
    state $sig = signature(
      method => 1,
      named  => [
        a => HashLike,
        b => HashLike,
      ],
    );
    ( $class, my $args ) = $sig->( @_ );
    $self = {
      a => TPoint->new( x => $args->{a}{x}, y => $args->{a}{y} ),
      b => TPoint->new( x => $args->{b}{x}, y => $args->{b}{y} ),
    };
  } 
  else {
    state $sig = signature(
      method => 1,
      named  => [
        ax => Int,
        ay => Int,
        bx => Int,
        by => Int,
      ],
    );
    ( $class, my $args ) = $sig->( @_ );
    $self = {
      a => TPoint->new( x => $args->{ax}, y => $args->{ay} ),
      b => TPoint->new( x => $args->{bx}, y => $args->{by} ),
    };
  }
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
} #/ sub new

sub from {    # $obj ($ax, $ay, $bx, $by)
  state $sig = signature(
    method => 1,
    pos    => [Int, Int, Int, Int],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( ax => $args[0], ay => $args[1], bx => $args[2], 
    by => $args[3] );
}

sub assign {    # void ($ax, $ay, $bx, $by)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int, Int, Int],
  );
  my ( $self, $ax, $ay, $bx, $by ) = $sig->( @_ );
  $self->{a}{x} = $ax;
  $self->{a}{y} = $ay;
  $self->{b}{x} = $bx;
  $self->{b}{y} = $by;
  return;
} #/ sub assign

sub clone {    # $rect ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $class = ref $self;
  return $class->new(
    a => $self->{a}->clone(),
    b => $self->{b}->clone(),
  );
}

sub dump {    # $str ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  require Data::Dumper;
  local $Data::Dumper::Sortkeys = 1;
  return Data::Dumper::Dumper $self;
}

sub move {    # void ($aDX, $aDY)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int],
  );
  my ( $self, $aDX, $aDY ) = $sig->( @_ );
  $self->{a}{x} += $aDX;
  $self->{a}{y} += $aDY;
  $self->{b}{x} += $aDX;
  $self->{b}{y} += $aDY;
  return;
}

sub grow {    # void ($aDX, $aDY)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int],
  );
  my ( $self, $aDX, $aDY ) = $sig->( @_ );
  $self->{a}{x} -= $aDX;
  $self->{a}{y} -= $aDY;
  $self->{b}{x} += $aDX;
  $self->{b}{y} += $aDY;
  return;
}

sub intersect {    # void ($r)
  state $sig = signature(
    method => Object,
    pos    => [HashLike],
  );
  my ( $self, $r ) = $sig->( @_ );
  $self->{a}{x} = max( $self->{a}{x}, $r->{a}{x} );
  $self->{a}{y} = max( $self->{a}{y}, $r->{a}{y} );
  $self->{b}{x} = min( $self->{b}{x}, $r->{b}{x} );
  $self->{b}{y} = min( $self->{b}{y}, $r->{b}{y} );
  return;
}

sub Union {    # void ($r)
  state $sig = signature(
    method => Object,
    pos    => [HashLike],
  );
  my ( $self, $r ) = $sig->( @_ );
  $self->{a}{x} = min( $self->{a}{x}, $r->{a}{x} );
  $self->{a}{y} = min( $self->{a}{y}, $r->{a}{y} );
  $self->{b}{x} = max( $self->{b}{x}, $r->{b}{x} );
  $self->{b}{y} = max( $self->{b}{y}, $r->{b}{y} );
  return;
}

sub contains {    # $bool ($p)
  state $sig = signature(
    method => Object,
    pos    => [HashLike],
  );
  my ( $self, $p ) = $sig->( @_ );
  return
       $p->{x} >= $self->{a}{x}
    && $p->{x} <  $self->{b}{x}
    && $p->{y} >= $self->{a}{y}
    && $p->{y} <  $self->{b}{y};
}

sub equal {    # $bool ($r, |$swap)
  state $sig = signature(
    pos => [HashLike, HashLike, Bool, { optional => 1 }],
  );
  my ( $one, $two, $swap ) = $sig->( @_ );
  return
       $one->{a}{x} == $two->{a}{x}
    && $one->{a}{y} == $two->{a}{y}
    && $one->{b}{x} == $two->{b}{x}
    && $one->{b}{y} == $two->{b}{y};
}

sub not_equal {    # $bool ($r, |$swap)
  state $sig = signature(
    pos => [HashLike, HashLike, Bool, { optional => 1 }],
  );
  my ( $one, $two, $swap ) = $sig->( @_ );
  return !equal( $one, $two );
}

sub isEmpty {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{a}{x} >= $self->{b}{x} 
      || $self->{a}{y} >= $self->{b}{y};
}

use overload
  '==' => \&equal,
  '!=' => \&not_equal,
  fallback => 1;

my $mk_accessors = sub {
  my ( $pkg ) = @_;
  assert ( @_ == 1 );
  assert ( defined $pkg );
  no strict 'refs';
  my %HAS = %{"${pkg}::HAS"};
  for my $field ( keys %HAS ) {
    my $full_name = "${pkg}::$field";
    *$full_name = sub {
      assert ( is_Object $_[0] );
      if ( @_ > 1 ) {
        assert ( is_Object $_[1] );
        $_[0]->{$field} = $_[1]->clone();
      }
      $_[0]->{$field};
    };
  } #/ for my $field ( keys %HAS)
}; #/ $mk_accessors = sub

__PACKAGE__->$mk_accessors();

1

__END__

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

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
