
package TV::Objects::NSSortedCollection;
# ABSTRACT: Defines the class TNSSortedCollection

use 5.010;
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

use TV::toolkit;
use TV::toolkit::Types qw( :types );

use TV::Objects::Const qw( ccNotFound );
use TV::Objects::NSCollection;

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

# public attributes
has duplicates => ( is => 'rw', default => false );

sub search {    # $bool ($key|undef, \$index)
  state $sig = signature(
    method => Object,
    pos    => [Any, ScalarRef],
  );
  my ( $self, $key, $index_ref ) = $sig->( @_ );
  my $l   = 0;
  my $h   = $self->{count} - 1;
  my $res = false;
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
        $res = true;
        $l   = $i unless $self->{duplicates};
      }
    }
  } #/ while ( $l <= $h )
  $$index_ref = $l;
  return $res;
} #/ sub search

sub indexOf {    # $index ($item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Item],
  );
  my ( $self, $item ) = $sig->( @_ );
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
  state $sig = signature(
    method => Object,
    pos    => [Item],
  );
  my ( $self, $item ) = $sig->( @_ );
  my $i;
  if ( !$self->search( $self->keyOf( $item ), \$i ) || $self->{duplicates} ) {
    $self->atInsert( $i, $item );
  }
  return $i;
}

sub keyOf {    # $key ($item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Item],
  );
  my ( $self, $item ) = $sig->( @_ );
  return $item;
}

sub compare {    # $cmp ($key1, $key2)
  state $sig = signature(
    method => Object,
    pos    => [Any, Any],
  );
  $sig->( @_ );
  return 0;
}

1

__END__

=pod

=head1 NAME

TNSSortedCollection - defines the NS class for TSortedCollection

=head1 DESCRIPTION

In this Perl module, the class I<TNSSortedCollection> is created, which inherits
from I<TNSCollection>. 

The NS variants of collections are Not Storable.  These are needed for 
internal use in the stream manager.  There are storable variants of each of 
these classes for use by the rest of the library.

=head1 METHODS

The methods I<new>, I<search>, I<indexOf>, I<insert>, I<keyOf> and I<compare> 
are implemented to provide the same behavior as in the Borland C++ code. The 
I<compare> method is defined as a abstract method that must be implemented in a 
subclass.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2024-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
