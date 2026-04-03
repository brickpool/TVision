package TV::Objects::Point;
# ABSTRACT: defines the class TPoint

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TPoint
  new_TPoint
);

use Devel::StrictMode;
use PerlX::Assert::PP;
use if STRICT => 'Hash::Util';
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  :is
  :types
);

sub TPoint() { __PACKAGE__ }
sub new_TPoint { __PACKAGE__->from(@_) }

# public attributes
our %HAS; BEGIN {
  %HAS = ( 
    x => sub { 0 },
    y => sub { 0 },
  );
}

sub new {    # \$obj (%args)
  state $sig = signature(
    method => 1,
    named  => [
      x => Int, { default => 0 },
      y => Int, { default => 0 },
    ],
  );
  my ( $class, $self ) = $sig->( @_ );
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
}

sub from {    # $obj ($x, $y)
  state $sig = signature(
    method => 1,
    pos => [Int, Int],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( x => $args[0], y => $args[1] );
}

sub clone {    # $p ()
  state $sig = signature(
    method => 1,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $class = ref $self || $self;
  return $class->new( %$self );
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

sub add {    # $p ($one, $two, |$swap)
  state $sig = signature(
    pos => [HashLike, HashLike, Bool, { optional => 1 }],
  );
  my ( $one, $two, $swap ) = $sig->( @_ );
  return TPoint->new( x => $one->{x} + $two->{x}, y => $one->{y} + $two->{y} );
}

sub subtract {    # $p ($one, $two, |$swap)
  state $sig = signature(
    pos => [HashLike, HashLike, Bool, { optional => 1 }],
  );
  my ( $one, $two, $swap ) = $sig->( @_ );
  ( $one, $two ) = ( $two, $one ) if $swap;
  return TPoint->new( x => $one->{x} - $two->{x}, y => $one->{y} - $two->{y} );
}

sub equal {    # $bool ($one, $two, |$swap)
  state $sig = signature(
    pos => [HashLike, HashLike, Bool, { optional => 1 }],
  );
  my ( $one, $two, $swap ) = $sig->( @_ );
  return $one->{x} == $two->{x} && $one->{y} == $two->{y};
}

sub not_equal {    # $bool ($one, $two, |$swap)
  state $sig = signature(
    pos => [HashLike, HashLike, Bool, { optional => 1 }],
  );
  my ( $one, $two, $swap ) = $sig->( @_ );
  return !equal( $one, $two );
}

sub add_assign {    # $self ($adder, |$wap)
  state $sig = signature(
    method => Object,
    pos    => [HashLike, Bool, { optional => 1 }],
  );
  my ( $self, $adder, $swap ) = $sig->( @_ );
  assert ( not $swap );
  $self->{x} += $adder->{x};
  $self->{y} += $adder->{y};
  return $self;
}

sub subtract_assign {    # $self ($subber, |$wap)
  state $sig = signature(
    method => Object,
    pos    => [HashLike, Bool, { optional => 1 }],
  );
  my ( $self, $subber, $swap ) = $sig->( @_ );
  assert ( not $swap );
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
        assert ( is_Int $_[1] );
        $_[0]->{$field} = $_[1];
      }
      $_[0]->{$field};
    };
  } #/ for my $field ( keys %HAS)
}; #/ $mk_accessors = sub

__PACKAGE__->$mk_accessors();

1

__END__

=pod

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
