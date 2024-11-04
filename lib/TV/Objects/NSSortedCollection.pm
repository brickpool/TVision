
=pod

=head1 NAME

TV::Objects::NSSortedCollection - defines the class TNSSortedCollection

=head1 DECRIPTION

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

use Exporter 'import';
our @EXPORT = qw(
  TNSSortedCollection
);

use Carp;

use TV::Objects::Const qw( CC_NOT_FOUND );
use TV::Objects::NSCollection;

sub TNSSortedCollection() { __PACKAGE__ }

my $REF = TNSCollection->{REF};

use parent TNSCollection;

sub new {    # $obj (%args)
  my ( $class, %args ) = @_;
  my $self = $class->SUPER::new( %args );
  $self->{duplicates} = !!0;
  $self->{delta}      = $args{delta} // 0;
  $self->setLimit( $args{limit} ) if defined $args{limit};
  return $self;
}

sub search {    # $bool ($key, \$index)
  my ( $self, $key, $index_ref ) = @_;
  my $l   = 0;
  my $h   = $self->{count} - 1;
  my $res = !!0;
  while ( $l <= $h ) {
    my $i = int( ( $l + $h ) / 2 );
    my $item = $REF->{ $self->{items}->[$i] };
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

sub indexOf {    # $index ($item)
  my ( $self, $item ) = @_;
  my $i;
  if ( !$self->search( $self->keyOf( $item ), \$i ) ) {
    return CC_NOT_FOUND;
  }
  else {
    if ( $self->{duplicates} ) {
      while ( $i < $self->{count} && $item ne $REF->{ $self->{items}->[$i] } ) {
        $i++;
      }
    }
    return $i < $self->{count} ? $i : CC_NOT_FOUND;
  }
} #/ sub indexOf

sub insert {    # $index ($item)
  my ( $self, $item ) = @_;
  my $i;
  if ( !$self->search( $self->keyOf( $item ), \$i ) || $self->{duplicates} ) {
    $self->atInsert( $i, $item );
  }
  return $i;
}

sub keyOf {    # $key ($item)
  my ( $self, $item ) = @_;
  return $item;
}

sub compare {    # $cmd ($key1, $key2)
  return 0;
}

1
