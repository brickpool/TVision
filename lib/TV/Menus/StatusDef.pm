package TV::Menus::StatusDef;
# ABSTRACT: Class linking a range of helps with a list of status line items

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStatusDef
  new_TStatusDef
);

use Carp ();
use PerlX::Assert::PP;
use TV::toolkit;
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  is_Object
  :types
);

use TV::Menus::StatusItem;

sub TStatusDef() { __PACKAGE__ }
sub new_TStatusDef { __PACKAGE__->from(@_) }

# public attributes
has next  => ( is => 'rw' );
has min   => ( is => 'rw', default => sub { die 'required' } );
has max   => ( is => 'rw', default => sub { die 'required' } );
has items => ( is => 'rw' );

# predeclare private methods
my (
  $add_status_item,
  $add_status_def,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      min   => PositiveOrZeroInt, { alias => 'aMin' },
      max   => PositiveOrZeroInt, { alias => 'aMax' },
      items => Object,            { alias => 'someItems', optional => 1 },
      next  => Object,            { alias => 'aNext',     optional => 1 },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return $args;
}

sub from {    # $obj ($aMin, $aMax, | $someItems, | $aNext)
  state $sig = signature(
    method => 1,
    pos    => [
      PositiveOrZeroInt,
      PositiveOrZeroInt,
      Object, { optional => 1 },
      Object, { optional => 1 },
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  SWITCH: for ( scalar @args ) {
    $_ == 2 and return $class->new( min => $args[0], max => $args[1] );
    $_ == 3 and return $class->new( min => $args[0], max => $args[1], 
      items => $args[2] );
    $_ == 4 and return $class->new( min => $args[0], max => $args[1], 
      items => $args[2], next => $args[3] );
  }
  return ;
}

sub _add_status_item { goto &$add_status_item }
$add_status_item = sub {    # $s1 ($s1, $s2, |undef)
  my ( $s1, $s2 ) = @_;
  assert ( @_ >= 2 && @_ <= 3 );
  assert ( is_Object $s1 );
  assert ( is_Object $s2 and $s2->isa( TStatusItem ) );
  my $def = $s1;
  while ( $def->{next} ) {
    $def = $def->{next};
  }
  if ( !$def->{items} ) {
    $def->{items} = $s2;
  }
  else {
    my $cur = $def->{items};
    while ( $cur->{next} ) {
      $cur = $cur->{next};
    }
    $cur->{next} = $s2;
  }
  return $s1;
};

sub _add_status_def { goto &$add_status_def }
$add_status_def = sub {    # $s1 ($s1, $s2, |undef)
  my ( $s1, $s2 ) = @_;
  assert ( @_ >= 2 && @_ <= 3 );
  assert ( is_Object $s1 );
  assert ( is_Object $s2 and $s2->isa( TStatusDef ) );
  my $cur = $s1;
  while ( $cur->{next} ) {
    $cur = $cur->{next};
  }
  $cur->{next} = $s2;
  return $s1;
};

sub add {    # $s1 ($s1, $s2, |$swap)
  state $sig = signature(
    pos => [
      Object,
      Object,
      Bool, { optional => 1 } 
    ],
  );
  my ( $s1, $s2, $swap ) = $sig->( @_ );
  assert ( not $swap );    # test if operands have been swapped
  $s2->isa( TStatusDef )
    ? goto &$add_status_def
    : goto &$add_status_item
}

use overload
  '+' => \&add,
  fallback => 1;

1

__END__

=pod

=head1 NAME

TV::Menus::StatusDef - defines the class TStatusDef

=cut
