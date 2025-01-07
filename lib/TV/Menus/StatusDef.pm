=pod

=head1 NAME

TV::Menus::StatusDef - defines the class TStatusDef

=cut

package TV::Menus::StatusDef;

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

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Menus::StatusItem;
use TV::toolkit;

sub TStatusDef() { __PACKAGE__ }
sub new_TStatusDef { __PACKAGE__->from(@_) }

# declare attributes
has next  => ( is => 'rw' );
has min   => ( is => 'rw', default => sub { 0 } );
has max   => ( is => 'rw', default => sub { 0 } );
has items => ( is => 'rw' );

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'required' arguments
  assert ( looks_like_number $args{min} );
  assert ( looks_like_number $args{max} );
  # check 'isa' (note: 'next' and 'items' can be undefined)
  assert( !defined $args{next}  or blessed $args{next} );
  assert( !defined $args{items} or blessed $args{items} );
  return \%args;
}

sub from {    # $obj ($aMin, $aMax, | $someItems, | $aNext)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ >= 2 && @_ <= 4 );
  return $class->new( min => $_[0], max => $_[1] );
}

sub add_status_item {    # $s1 ($s1, $s2)
  my ( $s1, $s2 ) = @_;
  assert ( blessed $s1 );
  assert ( blessed $s2 and $s2->isa( TStatusItem ) );
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
} #/ sub add_status_item

sub add_status_def {    # $s1 ($s1, $s2)
  my ( $s1, $s2 ) = @_;
  assert ( blessed $s1 );
  assert ( blessed $s2 and $s2->isa( TStatusDef ) );
  my $cur = $s1;
  while ( $cur->{next} ) {
    $cur = $cur->{next};
  }
  $cur->{next} = $s2;
  return $s1;
}

sub add {    # $s1 ($s1, $s2)
  assert ( blessed $_[0] );
  assert ( blessed $_[1] );
  assert ( not $_[2] );    # test if operands have been swapped
  blessed( $_[1] ) && $_[1]->isa( TStatusDef )
    ? goto &add_status_def
    : goto &add_status_item
}

use overload
  '+' => \&add,
  fallback => 1;

1
