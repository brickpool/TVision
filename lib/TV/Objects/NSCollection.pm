package TV::Objects::NSCollection;
# ABSTRACT: defines the class TNSCollection

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TNSCollection
  new_TNSCollection
);

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Errno qw( EFAULT EINVAL );
use Hash::Util::FieldHash qw( id );
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Objects::Const qw( 
  ccNotFound 
  maxCollectionSize
);
use TV::Objects::Object;
use TV::toolkit;

sub TNSCollection() { __PACKAGE__ }
sub new_TNSCollection { __PACKAGE__->from(@_) }

extends TObject;

# predeclare global variable
our %ITEMS = ();

# declare attributes
has items        => ( is => 'rw', default => sub { [] }  );
has count        => ( is => 'rw', default => sub { 0 }   );
has limit        => ( is => 'rw', default => sub { 0 }   );
has delta        => ( is => 'rw', default => sub { 0 }   );
has shouldDelete => ( is => 'rw', default => sub { !!1 } );

# predeclare private methods
my (
  $freeItem,
);

sub BUILDARGS {    # \%args (|%args)
  my $class = shift;
  assert ( $class and !ref $class );
  return STRICT ? check( {
    limit => { default => 0, defined => 1, allow => qr/^\d+$/ },
    delta => { default => 0, defined => 1, allow => qr/^\d+$/ },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
}

sub BUILD {    # void (|\%args)
  my ( $self, $args ) = @_;
  assert( blessed $self );
  $self->setLimit( $self->{limit} );
  return;
} #/ sub BUILD

sub from {    # $obj ($aLimit, $aDelta)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 2 );
  return $class->new( limit => $_[0], delta => $_[1] );
}

sub DEMOLISH {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->shutDown();
  return;
}

sub shutDown {    # void ()
  my $self = shift;
  assert ( blessed $self );
  if ( $self->{shouldDelete} ) {
    $self->freeAll();
  }
  else {
    $self->removeAll();
  }
  $self->setLimit( 0 );
  $self->SUPER::shutDown();
  return;
} #/ sub shutDown

sub at {    # $item ($index)
  my ( $self, $index ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $index );
  $self->error( EINVAL, "Index out of bounds" )
    if $index < 0 || $index >= $self->{count};
  return $ITEMS{ $self->{items}->[$index] };
}

sub atRemove {    # void ($index)
  my ( $self, $index ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $index );
  $self->error( EINVAL, "Index out of bounds" )
    if $index < 0 || $index >= $self->{count};
  $self->{count}--;
  splice( @{ $self->{items} }, $index, 1 );
  return;
}

sub atFree {    # void ($index)
  my ( $self, $index ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $index );
  my $item = $self->at( $index );
  $self->atRemove( $index );
  $self->$freeItem( $item );
  return;
}

sub atInsert {    # void ($index, $item|undef)
  my ( $self, $index, $item ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $index );
  assert ( @_ == 3 );
  $self->error( EINVAL, "Index out of bounds" )
    if $index < 0;
  $self->setLimit( $self->{count} + $self->{delta} )
    if $self->{count} == $self->{limit};

  my $id = id($item) || 0;
  $ITEMS{ $id } = $item;
  $self->{count}++;

  splice( @{ $self->{items} }, $index, 0, $id );
  return;
}

sub atPut {    # void ($index, $item|undef)
  my ( $self, $index, $item ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $index );
  assert ( @_ == 3 );
  $self->error( EINVAL, "Index out of bounds" )
    if $index >= $self->{count};

  my $id = id($item) || 0;
  $ITEMS{ $id } = $item;
  $self->{items}->[$index] = $id;
  return;
}

sub remove {    # void ($item)
  my ( $self, $item ) = @_;
  assert ( blessed $self );
  assert ( @_ == 2 );
  $self->atRemove( $self->indexOf( $item ) );
  return;
}

sub removeAll {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->{count} = 0;
  $self->{items} = [];
  return;
}

sub free {    # void ($item)
  my ( $self, $item ) = @_;
  assert ( blessed $self );
  assert ( @_ == 2 );
  $self->remove( $item );
  $self->$freeItem( $item );
  return;
}

sub freeAll {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->$freeItem( $self->at( $_ ) ) 
    for 0 .. $self->{count} - 1;
  $self->{count} = 0;
  return;
}

sub indexOf {    # $index ($item|undef)
  my ( $self, $item ) = @_;
  assert ( blessed $self );
  assert ( @_ == 2 );
  for my $i ( 0 .. $self->{count} - 1 ) {
    my $id = id($item) || 0;
    return $i if $self->{items}->[$i] eq $id;
  }
  $self->error( EFAULT, "Item not found" );
  return ccNotFound;
}

sub insert {    # $index ($item|undef)
  my ( $self, $item ) = @_;
  assert ( blessed $self );
  assert ( @_ == 2 );
  my $loc = $self->{count};
  $self->atInsert( $self->{count}, $item );
  return $loc;
}

sub error {    # void ($code, $info)
  my ( $self, $code, $info ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $code );
  assert ( defined $info and !ref $info );
  Carp::croak sprintf("Error code: %d, Info: %s\n", $code, $info);
}

sub firstThat {    # $item|undef (\&Test, $arg|undef)
  my ( $self, $Test, $arg ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( ref $Test );
  my $that;
  for my $i ( 0 .. $self->{count} - 1 ) {
    local $_ = $ITEMS{ $self->{items}->[$i] };
    return $_ if $Test->( $_, $arg );
  }
  return undef;
}

sub lastThat {    # $item|undef (\&Test, $arg|undef)
  my ( $self, $Test, $arg ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( ref $Test );
  my $that;
  for my $i ( reverse 0 .. $self->{count} - 1 ) {
    local $_ = $ITEMS{ $self->{items}->[$i] };
    return $_ if $Test->( $_, $arg );
  }
  return undef;
}

sub forEach {    # void (\&action, $arg|undef)
  my ( $self, $action, $arg ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( ref $action );
  for my $i ( 0 .. $self->{count} - 1 ) {
    local $_ = $ITEMS{ $self->{items}->[$i] };
    $action->( $_, $arg );
  }
  return;
}

sub pack {    # void ()
  my $self  = shift;
  assert ( blessed $self );
  my $count = 0;
  for my $i ( 0 .. $self->{count} - 1 ) {
    if ( $ITEMS{ $self->{items}->[$i] } ) {
      $count++;
    }
    else {
      splice( @{ $self->{items} }, $i, 1 );
    }
  }
  if ( $self->{count} != $count ) {
    my $n = $self->{count} - $count;
    push( @{ $self->{items} }, ( 0 ) x $n );
    $self->{count} = $count;
  }
  return;
}

sub setLimit {    # void ($aLimit)
  my ( $self, $aLimit ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aLimit );
  $aLimit = $self->{count} if $aLimit < $self->{count};
  $aLimit = maxCollectionSize if $aLimit > maxCollectionSize;
  if ( $aLimit != $self->{limit} ) {
    my $size = @{ $self->{items} };
    if ( $aLimit > $size ) {
      my $n = $aLimit - $size;
      push( @{ $self->{items} }, ( 0 ) x $n );
    } elsif ( $aLimit < $size ) {
      splice( @{ $self->{items} }, $aLimit );
    }
    $self->{limit} = $aLimit;
  }
  return;
} #/ sub setLimit

$freeItem = sub {
  my ( $self, $item ) = @_;
  my $id = id($item) || 0;
  delete $ITEMS{ $id } if $id;
  return;
};

1

__END__

=pod

=head1 NAME

TV::Objects::NSCollection provides a mechanism for managing any data collection.

=head1 DESCRIPTION

In this Perl module, the class I<TNSCollection> is created, which contains the 
same methods as the Borland C++ class. 

The NS variants of collections are Not Storable.  These are needed for 
internal use in the stream manager.  There are storable variants of each of 
these classes for use by the rest of the library.

=head1 ATTRIBUTES

=over

=item items

A list of items contained in the collection.

=item count

The current number of items in the collection.

=item limit

The maximum number of items the collection can hold.

=item delta

The amount by which the collection size increases when the limit is reached.

=item shouldDelete

A flag indicating whether items should be deleted when removed from the 
collection.

=back

=head1 METHODS

The methods I<new>, I<DEMOLISH>, I<shutDown>, I<at>, I<atRemove>, I<atFree>, 
I<atInsert>, I<atPut>, I<remove>, I<removeAll>, I<free>, I<freeAll>, 
I<freeItem>, I<indexOf>, I<insert>, I<error>, I<firstThat>, I<lastThat>, 
I<forEach>, I<pack> and I<setLimit> are implemented to provide the same behavior
as in Borland C++.

=head2 new

  my $collection = TNSCollection->new(limit => $aLimit, delta => $aDelta);

Creates a new TNSCollection with specified limit and delta.

=head2 DESTROY

  $self->DESTROY();

Destroys the TNSCollection object.

=head2 at

  my $item = $self->at($index);

Retrieves the item at the specified index.

=head2 atFree

  $self->atFree($index);

Frees the item at the specified index.

=head2 atInsert

  $self->atInsert($index, $item | undef);

Inserts an item at the specified index.

=head2 atPut

  $self->atPut($index, $item | undef);

Puts an item at the specified index.

=head2 atRemove

  $self->atRemove($index);

Removes the item at the specified index.

=head2 error

  $self->error($code, $info);

Handles errors with the given code and info.

=head2 firstThat

  my $item | undef = $self->firstThat(\&Test, $arg | undef);

Finds the first item that matches the test function.

=head2 forEach

  $self->forEach(\&action, $arg | undef);

Executes an action for each item in the collection.

=head2 free

  $self->free($item);

Frees the specified item.

=head2 freeAll

  $self->freeAll();

Frees all items in the collection.

=head2 from

  my $collection = TNSCollection->from($aLimit, $aDelta);

Creates a TNSCollection from specified limit and delta.

=head2 indexOf

  my $index = $self->indexOf($item | undef);

Returns the index of the specified item.

=head2 insert

  my $index = insert($item | undef);

Inserts an item into the collection.

=head2 lastThat

  my $item | undef = $self->lastThat(\&Test, $arg | undef);

Finds the last item that matches the test function.

=head2 pack

  $self->pack();

Packs the collection to remove gaps.

=head2 remove

  $self->remove($item);

Removes the specified item from the collection.

=head2 removeAll

  $self->removeAll();

Removes all items from the collection.

=head2 setLimit

  $self->setLimit($aLimit);

Sets the limit for the collection.

=head2 shutDown

  $self->shutDown();

Shuts down the collection.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2025 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
