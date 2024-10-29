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

The methods I<new>, I<DESTROY>, I<shutDown>, I<at>, I<atRemove>, I<atFree>, 
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

use Errno qw( EFAULT EINVAL );
use Hash::Util::FieldHash qw( id );

use TV::Objects::Const qw(
  CC_NOT_FOUND 
  MAX_COLLECTION_SIZE
);
use TV::Objects::Object;

sub TNSCollection() { __PACKAGE__ }

# predeclare global variable names
our %REF;
{
  no warnings 'once';
  *TNSCollection::REF = \%REF;
}

use parent TObject;

sub new {    # $obj ($class, %args)
  my ( $class, %args ) = @_;
  my $self = bless {
    count        => 0,
    items        => [],
    limit        => $args{limit} // 0,
    delta        => $args{delta} // 0,
    shouldDelete => !!1,
  }, $class;
  $self->setLimit( $args{limit} ) if defined $args{limit};
  return $self;
} #/ sub new

sub DESTROY {    # void ($shift)
  my $self = shift;
  $self->shutDown();
  return;
}

my $freeItem = sub {
  my ( $self, $item ) = @_;
  my $id = id($item) || 0;
  delete $REF{ $id } if $id;
  return;
};

sub shutDown {    # void ($shift)
  my $self = shift;
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

sub at {    # $item ($self, $index)
  my ( $self, $index ) = @_;
  $self->error(EINVAL, "Index out of bounds")
    if $index < 0 || $index >= $self->{count};
  return $REF{ $self->{items}->[$index] };
}

sub atRemove {    # void ($self, $index)
  my ( $self, $index ) = @_;
  $self->error(EINVAL, "Index out of bounds")
    if $index < 0 || $index >= $self->{count};
  $self->{count}--;
  splice( @{ $self->{items} }, $index, 1 );
  return;
}

sub atFree {    # void ($self, $index)
  my ( $self, $index ) = @_;
  my $item = $self->at( $index );
  $self->atRemove( $index );
  $self->$freeItem( $item );
  return;
}

sub atInsert {    # void ($self, $index, $item)
  my ( $self, $index, $item ) = @_;
  $self->error(EINVAL, "Index out of bounds")
    if $index < 0;
  $self->setLimit( $self->{count} + $self->{delta} )
    if $self->{count} == $self->{limit};

  my $id = id($item) || 0;
  $REF{ $id } = $item;
  $self->{count}++;

  splice( @{ $self->{items} }, $index, 0, $id );
  return;
}

sub atPut {    # void ($self, $index, $item)
  my ( $self, $index, $item ) = @_;
  $self->error(EINVAL, "Index out of bounds")
    if $index >= $self->{count};

  my $id = id($item) || 0;
  $REF{ $id } = $item;
  $self->{items}->[$index] = $id;
  return;
}

sub remove {    # void ($self, $item)
  my ( $self, $item ) = @_;
  $self->atRemove( $self->indexOf( $item ) );
  return;
}

sub removeAll {    # void ($self)
  my $self = shift;
  $self->{count} = 0;
  $self->{items} = [];
  return;
}

sub free {    # void ($self, $item)
  my ( $self, $item ) = @_;
  $self->remove( $item );
  $self->$freeItem( $item );
  return;
}

sub freeAll {    # void ($self)
  my $self = shift;
  $self->$freeItem( $self->at( $_ ) ) 
    for 0 .. $self->{count} - 1;
  $self->{count} = 0;
  return;
}

sub indexOf {    # $index ($self, $item)
  my ( $self, $item ) = @_;
  for my $i ( 0 .. $self->{count} - 1 ) {
    my $id = id($item) || 0;
    return $i if $self->{items}->[$i] eq $id;
  }
  $self->error(EFAULT, "Item not found");
  return CC_NOT_FOUND;
}

sub insert {    # $index ($self, $item)
  my ( $self, $item ) = @_;
  my $loc = $self->{count};
  $self->atInsert( $self->{count}, $item );
  return $loc;
}

sub error {    # void ($self, \&code, $info)
  require Carp;
  my ( $self, $code, $info ) = @_;
  Carp::croak sprintf("Error code: %d, Info: %s\n", $code, $info);
}

sub firstThat {    # $item|undef ($self, \&test, $arg)
  my ( $self, $test, $arg ) = @_;
  my $that;
  for my $i ( 0 .. $self->{count} - 1 ) {
    local $_ = $REF{ $self->{items}->[$i] };
    return $_ if $test->( $_, $arg );
  }
  return undef;
}

sub lastThat {    # $item|undef ($self, \&test, $arg)
  my ( $self, $test, $arg ) = @_;
  my $that;
  for my $i ( reverse 0 .. $self->{count} - 1 ) {
    local $_ = $REF{ $self->{items}->[$i] };
    return $_ if $test->( $_, $arg );
  }
  return undef;
}

sub forEach {    # void ($self, \&action, $arg)
  my ( $self, $action, $arg ) = @_;
  for my $i ( 0 .. $self->{count} - 1 ) {
    local $_ = $REF{ $self->{items}->[$i] };
    $action->( $_, $arg );
  }
  return;
}

sub pack {    # void ($self)
  my $self  = shift;
  my $count = 0;
  for my $i ( 0 .. $self->{count} - 1 ) {
    if ( $REF{ $self->{items}->[$i] } ) {
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

sub setLimit {    # void ($self, $aLimit)
  my ( $self, $aLimit ) = @_;
  $aLimit = $self->{count} if $aLimit < $self->{count};
  $aLimit = MAX_COLLECTION_SIZE if $aLimit > MAX_COLLECTION_SIZE;
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

1
