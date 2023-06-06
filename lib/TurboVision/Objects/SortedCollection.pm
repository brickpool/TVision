=pod

=head1 NAME

TSortedCollection - Derivation of I<TCollection>, where items sorted by a key.

=head1 SYNOPSIS

  package TClientCollection {
    use Moose;
    use TurboVision::Objects;
  
    extends TSortedCollection->class;
  
    sub key_of {
      my ($self, $item) = @_;
      return $item->$name;
    }
  
    # return 0 if they're equal
    # return -1 if $key1 comes first
    # otherwise return 1; $key2 comes first
    sub compare {
      my ($self, $key1, $key2) = @_;
      return ${$key1} cmp ${$key2};
    }
  }

=cut

package TurboVision::Objects::SortedCollection;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use Function::Parameters {
  factory_inherit => {
    defaults    => 'method_strict',
    install_sub => 'around',
    shift       => ['$super', '$class'],
    runtime     => 1,
    name        => 'required',
  },
  around => {
    defaults    => 'method_strict',
    install_sub => 'around',
    shift       => ['$next', '$self'],
    runtime     => 1,
    name        => 'required',
  },
},
qw(
  method
);

use Moose;
use MooseX::Types::Moose qw( :all );
use MooseX::HasDefaults::RO;
use namespace::autoclean;

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:fpc';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Data::Alias qw( alias );
use Scalar::Util qw( refaddr weaken isweak );
use Try::Tiny;

use TurboVision::Const qw(
  :bool
  _UINT8_T
);
use TurboVision::Objects::Collection;
use TurboVision::Objects::Common qw(
  abstract
  byte
  fail
);
use TurboVision::Objects::Stream;
use TurboVision::Objects::Types qw(
  TCollection
  TSortedCollection
  TStream
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

When you want to have your collection sorted into some order (that you specify),
use the I<TSortedCollection> type.

Items added to a I<TSortedCollection> are always ordered by the order you
specify with a custom, overridden I<< TSortedCollection->compare >> function.

B<Commonly Used Features>

In addition to the inherited I<< TCollection->init >>, you'll use I<insert> to
add new items to the collection, I<delete> to remove items from the collection,
and finally, you must override I<key_of> and I<compare>.

=head2 Class

public class I<< TSortedCollection >>

Turbo Vision Hierarchy

  TObject
    TCollection
      TSortedCollection
        TStringCollection

=cut

package TurboVision::Objects::SortedCollection {

  extends TCollection->class;

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Attributes

=over

=item public C<< Bool duplicates >>

The default setting of I<duplicates> is false and this prohibits the addition
of duplicate entries to the collection.

If you change I<duplicates> to true, new duplicate entries will be inserted just
before any other items having the same key.

=cut

  has 'duplicates' => (
    is      => 'rw',
    isa     => Bool,
    default => _FALSE,
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => TSortedCollection;

=head2 Constructors

=over

=item public C<< TSortedCollection->load(TStream $s) >>

Constructs and loads a sorted collection from the stream I<$s> by first calling
the I<load> constructor inherited from I<TCollection>, then reading the
I<duplicates> attribute.

=cut

  factory_inherit load(TStream $s) {
    my $read = sub {
      SWITCH: foreach( $_[0] ) {
        /byte/ && do {
          $s->read(my $buf, byte->size);
          return byte( $buf )->unpack;
        };
      };
      return undef;
    };

    try {
      my $self = $class->$super($s);                      # Call ancestor
      my $duplicates = !! $read->('byte');                # Read duplicate flag
      $self->duplicates( $duplicates );
      return $self;
    }
    catch {
      return fail;
    }
  }

=back

=cut

  # ------------------------------------------------------------------------
  # TSortedCollection ------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item public C<< Int compare(Ref $key1, Ref $key2) >>

You must override I<compare> for your data object type.

Write a new I<compare> function to compare I<$$key1> to I<$$key2> and return a
value according to this:

  -1 if $$keyl <  $$key2
   0 if $$keyl == $$key2
   1 if $$keyl >  $$key2

=cut

  method compare(Ref $key1, Ref $key2) {
    abstract();
    return 0;
  }

=item public C<< Int index_of(Ref $item) >>

Where I<$item> is a reference to an object type that is stored in the
collection, I<index_of> returns the Index position where it is located, or -1
if the I<$item> is not found.

=cut

  around index_of(Ref $item) {
    my $index;
    return -1
      if !$self->search($self->key_of($item), $index);

    if ($self->duplicates) {
      COUNT:
      while ($index < $self->count) {
        last COUNT if refaddr($item) == refaddr($self->at($index));
        $index++;
      }
    }

    return $index < $self->count
          ? $index
          : -1
          ;
  }
 
=item public C<< insert(Ref $item) >>

Adds the I<$item> to the collection.

If I<$item> already exists in the collection, I<insert> checks the value of the
I<duplicates> attribute.

If I<duplicates> is false then the I<$item> is not added, but if I<duplicates>
is true, then the I<$item> is inserted just prior to any duplicate entries.

=cut

  around insert(Ref $item) {
    my $index;
    if (
      !$self->search( $self->key_of($item), $index )      # Item valid
      || $self->duplicates
    ) {
      $self->at_insert($index, $item)                     # Insert the item
    }
    return;
  }
 
=item public C<< Ref key_of(Ref $item) >>

You must override this function.

I<key_of> returns a reference to the specific attribute within the object that
is to be used as the sort key. For example,

  package TPersonCollection {
    ...
    sub key_of {
      my ($self, $item) = @_;
      return $item->name;
    }
  }

Here, the I<$item> reference is a object data type so that you can access its
attributes.

The content of the attribute to be used as the sort key is returned as the
result.

=cut

  method key_of(Ref $item) {
    return $item;                                         # Return item as key
  }
 
=item public C<< Bool search(Ref $key, Int $index) >>

Use I<search> to look for specific items in the collection.

The method I<search> returns true if the item was found, or false otherwise.

If found, I<$index> is set to the location in the collection where the item
resides.

=cut

  method search(Ref $key, $) {
    alias my $index = $_[-1];
    my ($retval, $low, $high, $i, $cmp);

    $retval = _FALSE;                                     # Preset failure
    $low = 0;                                             # Start count
    $high = $self->count - 1;                             # End count
    $index = 0;
    return $retval
      if $self->count == 0;

    while ($low <= $high) {
      $i = ($low + $high) >> 1;                           # Mid point
      my $item = $self->at($i);
      $cmp = defined $item
           ? $self->compare($self->key_of($item), $key)   # Compare with key
           : -1
           ;
      if ($cmp < 0) {
        $low = $i + 1;                                    # Item to left
      }
      else {
        $high = $i - 1;                                   # Item to right
        if ($cmp == 0) {
          $retval = _TRUE;                                # Result true
          $low = $i if !$self->duplicates;                # Force kick out
        }
      }
    }
    $index = $low;                                        # Return result
    return $retval;
  }
 
=item public C<< store(TStream $s) >>

Writes the sorted collection and all its items to the stream I<$s> by first
calling the I<store> method inherited from I<TCollection>, then writing the
I<duplicates> attribute introduced by I<TSortedCollection>.

=cut

  around store(TStream $s) {
    $self->$next($s);                                     # Call ancestor
    my $byte = pack(_UINT8_T, $self->duplicates ? 1 : 0);
    $s->write($byte, length $byte);                       # Write duplicate flag
    return;
  }

=back

=head2 Inheritance

Methods inherited from class C<TCollection>

  init, at, at_delte, at_free, at_insert, at_put, delete, delete_all, error,
  first_that, for_each, free, free_all, free_item, get_item, last_that, pack,
  put_item, selt_limit

Methods inherited from class L<Moose::Object>

  new, BUILDARGS, does, DOES, dump, DESTROY

=cut

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Free Pascal run time library.
 Copyright (c) 1999-2000 by the Free Pascal development team.

 Interface Copyright (c) 1992 Borland International

 The run-time files are licensed under modified LGPL.

 The creation of subclasses of this LGPL-licensed class is considered to be
 using an interface of a library, in analogy to a function call of a library.
 It is not considered a modification of the original class. Therefore,
 subclasses created in this way are not subject to the obligations that an LGPL
 imposes on licensees.

 POD sections by Ed Mitchell are licensed under modified CC BY-NC-ND.

=head1 AUTHORS

=over

=item *

1999-2000 by Florian Klaempfl E<lt>fnklaemp@cip.ft.uni-erlangen.deE<gt>

=item *

1999-2000 by Frank ZAGO E<lt>zago@ecoledoc.ipc.frE<gt>

=item *

1999-2000 by MH Spiegel

=item *

1996, 1999-2000 by Leon de Boer E<lt>ldeboer@ibm.netE<gt>

=item *

1992 by Ed Mitchell (Turbo Pascal Reference electronic freeware book)

=back

=head1 DISCLAIMER OF WARRANTIES

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.

=head1 MAINTAINER

=over

=item *

2021-2022 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

I<TCollection>, I<TStringCollection>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
