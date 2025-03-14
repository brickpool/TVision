
=pod

=head1 NAME

TV::Objects::NSSortedCollection - defines the class TNSSortedCollection

=head1 DESCRIPTION

In this Perl module, the class I<TNSSortedCollection> is created, which inherits
from I<TNSCollection>. 

The NS variants of collections are Not Storable.  These are needed for 
internal use in the stream manager.  There are storable variants of each of 
these classes for use by the rest of the library.

=head2 Methods

The methods I<new>, I<search>, I<indexOf>, I<insert>, I<keyOf> and I<compare> 
are implemented to provide the same behavior as in the Borland C++ code. The 
I<compare> method is defined as a abstract method that must be implemented in a 
subclass.

=cut

package TV::Objects::NSSortedCollection;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TNSSortedCollection
  new_TNSSortedCollection
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  readonly
);

use TV::Objects::Const qw( ccNotFound );
use TV::Objects::NSCollection;
use TV::toolkit;

sub TNSSortedCollection() { __PACKAGE__ }
sub new_TNSSortedCollection { __PACKAGE__->from(@_) }

extends TNSCollection;

# import global variables
use vars qw(
  %ITEMS 
);
{
  no strict 'refs';
  *ITEMS = \%{ TNSCollection . '::ITEMS' };
}

# declare attributes
has duplicates => ( is => 'rw', default => sub { !!0 } );

sub search {    # $bool ($key|undef, \$index)
  my ( $self, $key, $index_ref ) = @_;
  assert ( blessed $self );
  assert ( @_ == 3 );
  assert ( ref $index_ref and !readonly $$index_ref );
  my $l   = 0;
  my $h   = $self->{count} - 1;
  my $res = !!0;
  while ( $l <= $h ) {
    my $i = ( $l + $h ) >> 1;
    my $item = $ITEMS{ $self->{items}->[$i] };
    my $c = $self->compare( $self->keyOf( $item ), $key );
    if ( $c < 0 ) {
      $l = $i + 1;
    }
    else {
      $h = $i - 1;
      if ( $c == 0 ) {
        $res = !!1;
        $l   = $i unless $self->{duplicates};
      }
    }
  } #/ while ( $l <= $h )
  $$index_ref = $l;
  return $res;
} #/ sub search

sub indexOf {    # $index ($item|undef)
  my ( $self, $item ) = @_;
  assert ( blessed $self );
  assert ( @_ == 2 );
  my $i;
  if ( !$self->search( $self->keyOf( $item ), \$i ) ) {
    return ccNotFound;
  }
  else {
    if ( $self->{duplicates} ) {
      while ( $i < $self->{count} && $item ne $ITEMS{ $self->{items}->[$i] } ) {
        $i++;
      }
    }
    return $i < $self->{count} ? $i : ccNotFound;
  }
} #/ sub indexOf

sub insert {    # $index ($item|undef)
  my ( $self, $item ) = @_;
  assert ( blessed $self );
  assert ( @_ == 2 );
  my $i;
  if ( !$self->search( $self->keyOf( $item ), \$i ) || $self->{duplicates} ) {
    $self->atInsert( $i, $item );
  }
  return $i;
}

sub keyOf {    # $key ($item|undef)
  my ( $self, $item ) = @_;
  assert ( blessed $self );
  assert ( @_ == 2 );
  return $item;
}

sub compare {    # $cmd ($key1, $key2)
  assert ( blessed shift );
  assert ( @_ == 3 );
  return 0;
}

1
