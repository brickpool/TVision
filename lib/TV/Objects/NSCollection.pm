=pod

=head1 NAME

TV::Objects::NSCollection - defines the class TNSCollection

=head1 DESCRIPTION

In this Perl module, the class I<TNSCollection> is created, which contains the 
same methods as the Borland C++ class. 

The NS variants of collections are Not Storable.  These are needed for 
internal use in the stream manager.  There are storable variants of each of 
these classes for use by the rest of the library.

=head2 Methods

The methods I<new>, I<DEMOLISH>, I<shutDown>, I<at>, I<atRemove>, I<atFree>, 
I<atInsert>, I<atPut>, I<remove>, I<removeAll>, I<free>, I<freeAll>, 
I<freeItem>, I<indexOf>, I<insert>, I<error>, I<firstThat>, I<lastThat>, 
I<forEach>, I<pack> and I<setLimit> are implemented to provide the same behavior
as in Borland C++.

=cut

package TV::Objects::NSCollection;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TNSCollection
);

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Errno qw( EFAULT EINVAL );
use Hash::Util::FieldHash qw( id );
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Objects::Const qw( 
  ccNotFound 
  maxCollectionSize
);
use TV::Objects::Object;

sub TNSCollection() { __PACKAGE__ }

use base TObject;

# predeclare global variable
our %ITEMS = ();
{
  no warnings 'once';
  TNSCollection->{ITEMS} = \%ITEMS;
}

# predeclare attributes
use fields qw(
  items
  count
  limit
  delta
  shouldDelete
);

# predeclare private methods
my (
  $freeItem,
);

sub BUILD {    # void (| \%args)
  my ( $self, $args ) = @_;
  assert( blessed $self );
  my %default = (
    items        => [],
    count        => 0,
    limit        => 0,
    delta        => 0,
    shouldDelete => !!1,
  );
  map { $self->{$_} = $default{$_} }
    grep { !defined $self->{$_} }
      keys %default;
  $self->setLimit( $self->{limit} );
  return;
} #/ sub BUILD

sub DEMOLISH {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->shutDown();
  return;
}

sub shutDown {    # void ($shift)
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

sub removeAll {    # void ($self)
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

sub freeAll {    # void ($self)
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

sub firstThat {    # $item|undef (\&test, $arg|undef)
  my ( $self, $test, $arg ) = @_;
  assert ( blessed $self );
  assert ( ref $test );
  assert ( @_ == 3 );
  my $that;
  for my $i ( 0 .. $self->{count} - 1 ) {
    local $_ = $ITEMS{ $self->{items}->[$i] };
    return $_ if $test->( $_, $arg );
  }
  return undef;
}

sub lastThat {    # $item|undef (\&test, $arg|undef)
  my ( $self, $test, $arg ) = @_;
  assert ( blessed $self );
  assert ( ref $test );
  assert ( @_ == 3 );
  my $that;
  for my $i ( reverse 0 .. $self->{count} - 1 ) {
    local $_ = $ITEMS{ $self->{items}->[$i] };
    return $_ if $test->( $_, $arg );
  }
  return undef;
}

sub forEach {    # void (\&action, $arg|undef)
  my ( $self, $action, $arg ) = @_;
  assert ( blessed $self );
  assert ( ref $action );
  assert ( @_ == 3 );
  for my $i ( 0 .. $self->{count} - 1 ) {
    local $_ = $ITEMS{ $self->{items}->[$i] };
    $action->( $_, $arg );
  }
  return;
}

sub pack {    # void ($self)
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

__PACKAGE__->mk_accessors();

1
