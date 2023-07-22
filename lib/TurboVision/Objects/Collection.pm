=pod

=head1 NAME

TCollection - Base type for implementing a collection of items.

=head1 SYNOPSIS

  use TurboVision::Objects;
  use Scalar::Util qw( blessed );

  package TClient {
    use Moose;
    
    # attributes
    has ['account', 'name', 'phone'] => (
      is        => 'ro',
      isa       => 'Str',
      required  => 1,
    );
    
    # constructor
    sub init {
      my ($class, $new_account, $new_name, $new_phone) = @_;

      return $class->new(
        account => $new_account,
        name    => $new_name,
        phone   => $new_phone,
      );
    }
  }
  
  # print info for all clients
  sub print_all {
    my ($c) = @_;
    confess 'Invalid argument'
      if !blessed($c);
    
    my $print_client = sub {
      my ($p) = @_;
      return
          if !blessed($p)
      
      # show client info
      printf("%-20s%-20s%-20s\n"
      , $p->account
      , $p->name
      , $p->phone
      );
    }
     
    print("\n\n");
    # Call print_client for each item
    $c->for_each($print_client);
    return;
  }
  
  # search phone number as substring and print client data if found
  sub search_phone {
    my ($c, $phone_to_find) = @_;
    confess 'Invalid argument'
      if !blessed($c)
      || !defined($phone_to_find)
      || ref($phone_to_find)
    
    my $phone_match = sub {
      my ($client) = @_;
      return
          if !blessed($client)
          || !defined($client->phone)

      my $phone = $client->phone
      return $phone =~ qr/\Q$phone_to_find\E/;
    }
    
    my $found_client = $c->first_that($phone_match);
    if ( !$found_client ) {
      print("No client met the search requirement\n");
    }
    else {
      for ($found_client) {
        printf("Found client: %s %s %s\n"
        , $_->account
        , $_->name
        , $_->phone
        );
      }
    }
    return;
  }
  
  sub main {
    my $client_list = TCollection->init(50, 50);
    for ($client_list) {
      $_->insert(TClient->init('90-167', 'Smith, Zelda', '(800) 555-1212'));
      $_->insert(TClient->init('90-160', 'Johnson, Agatha', '(302) 139-8913'));
      $_->insert(TClient->init('90-177', 'Smitty, John', '(406) 987-4321'));
      $_->insert(TClient->init('90-100', 'Anders, Smitty', '(406) 111-2222'));
    }
    print_all($client_list);
    print("\n\n");
    search_phone($client_list, '(406)');
    return 0;
  }
  
  exit main( 1+@ARGV, $0, @ARGV );

=cut

package TurboVision::Objects::Collection;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use Function::Parameters {
  factory => {
    defaults    => 'classmethod_strict',
    shift       => '$class',
    name        => 'required',
  },
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
  }
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

use Carp;
use Config;
use Data::Alias qw( alias );
use English qw( -no_match_vars );
use Scalar::Util qw( refaddr weaken isweak );
use Try::Tiny;

use TurboVision::Objects::Common qw(
  fail
  word
);
use TurboVision::Objects::Const qw(
  :coXXXX
  MAX_COLLECTION_SIZE
);
use TurboVision::Objects::Stream;
use TurboVision::Objects::StreamRec;
use TurboVision::Objects::Types qw(
  TCollection
  TObject
  TStream
  TStreamRec
);

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

use Moose::Exporter;
Moose::Exporter->setup_import_methods(
  as_is => [ 'RCollection' ],
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

Collections provide a mechanism for storing and accessing arbitrary collections
of data. You can think of a collection as working like a dynamically sizeable
array of data, that can be enlarged as your data requirements increase. Several
specialized collections are derived from I<TCollection>, including
I<TSortedCollection>, I<TStringCollection> and I<TResourceCollection>. The
latter is used internally to the resource file mechanism and is not generally
used by application programs.

While collections are defined within Turbo Vision, you can also use
collections in standard, non-Turbo Vision applications.

In the description of the methods below, each method using an I<$index>
parameter checks to insure that the Index is in the valid range between 0
and L</count> (the number of items in the collection). If the I<$index> is out
range, these methods call L</error> which, by default, halts the program with a
run time error. You can trap any collection error by
overriding error in your derived collection.

B<Commonly Used Features>

L</count> attribute, L</init> constructor, the access methods L</at>,
L</at_put>, L</at_delete>, L</at_free>, the iterators L</first_that>,
L</for_each> and L</last_that>, the L</index_of> method, and the L</load>
constructor and L</store> method.

=head2 Class

public class I<< TCollection >>

Turbo Vision Hierarchy

  TObject
    TCollection
      TSortedCollection
        TStringCollection
      TResourceCollection

=cut

package TurboVision::Objects::Collection {

  extends TObject->class;

  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Constants

=over

=item I<RCollection>

  constant RCollection = < TStreamRec >;

Defining a registration record constant for I<TCollection>.

=cut

  use constant RCollection => TStreamRec->new(
    obj_type  => 50,
    vmt_link  => __PACKAGE__,
    load      => 'load',
    store     => 'store',
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Attributes

=over

=item I<count>

  field count ( is => ro, type => Int );

Holds the number of L</items> currently stored in the collection, up to
I<MAX_COLLECTION_SIZE>.

=cut

  #around count() {
  #  return $self->$next();
  #}

=item I<delta>

  has delta ( is => rwp, type => Int ) = 0;

Because one of the features of collections is that they can grow, I<delta>
holds the number of elements by which the collection should be enlarged
when the L</count> reaches the current maximum size specified by L</limit>.

When this occurs, L</limit> is increased by I<delta> and additional space is
reserved for the necessary L</items>.

Generally, L</limit> should initially be set to a sufficient size for most
operations on the collection, and I<delta> should be set large enough so that
expansion of the collection occurs infrequently to avoid the fairly intensive
overhead of dynamically resizing the collection.

=cut

  has 'delta' => (
    isa     => Int,
    default => 0,
    writer  => '_delta',
  );

=item I<items>

  has items ( is => rwp, type => ArrayRef[Ref] ) = [];

I<items> points to an array reference that contains reference to the individual
items in the collection.

=cut

  has 'items' => (
    isa     => ArrayRef[Ref],
    default => sub { [] },
    traits  => ['Array'],
    handles => {
      at          => 'get',
      at_delete   => 'delete',
      at_insert   => 'insert',
      at_put      => 'set',
      count       => 'count',
      delete_all  => 'clear',
      first_that  => 'first',
      index_of    => 'first_index',
      last_that   => 'grep',
    },
    writer  => '_items',
  );

=item I<limit>

  has limit ( is => rwp, type => Int ) = MAX_COLLECTION_SIZE;

Holds the current number of reserved elements for the collection.

=cut

  has 'limit' => (
    isa     => Int,
    default => MAX_COLLECTION_SIZE,
    writer  => '_limit',
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => TCollection;

=head2 Constructors

=over

=item I<init>

  factory init(Int $a_limit, Int $a_delta) : TCollection

The constructor I<init> creates a new collection with initially allocated array
for the number of elements specified by I<$a_limit>, and the ability to
dynamically increase the size of the collection in L</delta> increments.

See: I<MAX_COLLECTION_SIZE>

=cut

  factory_inherit init(Int $a_limit = 0, Int $a_delta = 0) {
    my $self = $class->$super();                          # Call ancestor
    return fail
        if !defined $self;

    $self->_delta( $a_delta );                            # Set increment
    $self->set_limit( $a_limit );                         # Set limit
    return $self;
  }

=item I<load>

  factory load(TStream $s) : TCollection

Loads the entire collection from stream I<$s>, by calling L</get_item> for each
individual item in the collection.

=cut

  factory load(TStream $s) {
    my $read = sub {
      my $type = shift;
      SWITCH: for( $type ) {
        /word/ && do {
          $s->read(my $buf, word->size);
          return word( $buf )->unpack;
        };
      };
      return undef;
    };

    try {
      my $count = 'word'->$read();                        # Read count
      my $limit = 'word'->$read();                        # Read limit
      my $delta = 'word'->$read();                        # Read delta
      my $self = $class->new(
        delta => $delta,
        limit => $limit,                                  # Set requested limit
      );
      GET_EACH_ITEM:                                      # Get each item
      for my $index (0..$count-1) {
        my $item = $self->get_item($s);
        $self->at_insert($index, $item);                  # Sets also count
      }
      return $self;
    }
    catch {
      return fail;
    }
  }

=back

=cut

  # ------------------------------------------------------------------------
  # TCollection ----------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item I<at>

  method at(Int $index) : Ref

Use I<at> to access the collection as if it were an array.

Normally I<at($index)> returns a reference to the I<$index>'th item in the
array, where I<$index> ranges from 0 up to L</count>.

If an error occurs, I<at> calls the L</error> method with an argument of
I<CO_INDEX_ERROR> and then returns C<undef>.

=cut

  around at(Int $index) {
    if ( $index < 0 || $index >= $self->count ) {         # Invalid index
      $self->error(CO_INDEX_ERROR, $index);               # Call error
      return undef;                                       # Return undef
    }
    return $self->$next($index);                          # Return item
  }

=item I<at_delete>

  method at_delete(Int $index)

The method I<at_delete> deletes the item at the location specified by I<$index>,
and slides all of the following L</items> in the collection over to fill in the
now vacant hole and decrements L</count> by 1.

The method I<at_delete> does not weaken all references to the item in the
collection that was in the location.

=cut

  around at_delete(Int $index) {
    if ( $index < 0 || $index >= $self->count ) {         # Valid index
      $self->error(CO_INDEX_ERROR, $index);               # Index error
      return;
    }
    $self->$next($index);                                 # Shuffle items down
    return;
  }

=item I<at_free>

  method at_free(Int $index)

The method I<at_free> works like L</at_delete>, except that the specific item is
deleted and all other references to this item in the collection are weakened.

=cut

  method at_free(Int $index) {
    my $item = $self->at($index);
    $self->at_delete($index);
    $self->free_item($item);
    return;
  }

=item I<at_insert>

  method at_insert(Int $index, Ref $item)

The method I<at_insert> puts a new I<$item> into the collection at the I<$index>
location by sliding all of the following L</items> over by one position.

If adding the new element would exceed the size of the collection, L</set_limit>
is called to automatically expand the size.

=cut

  around at_insert(Int $index, Ref $item) {
    if ( $index < 0 || $index > $self->count ) {          # Valid index
      $self->error(CO_INDEX_ERROR, $index);               # Index error
      return;
    }
    if ( $self->count >= $self->limit ) {
      $self->set_limit($self->limit + $self->delta);      # Expand size if able
      if ( $self->count >= $self->limit ) {
        $self->error(CO_OVERFLOW, $index);                # Expand failed
        return;
      }
    }
    $self->$next($index, $item);                          # Put item in list
    return;
  }

=item I<at_put>

  method at_put(Int $index, Ref $item)

Use I<at_put> when you need to replace an existing item with a new item.

The method I<at_put> copies the new I<$item> refernce to the location specified
by I<$index>.

=cut

  around at_put(Int $index, Ref $item) {
    if ( $index < 0 || $index >= $self->count ) {         # Valid index
      $self->error(CO_INDEX_ERROR, $index);               # Index error
      return;
    }
    $self->$next($index, $item);                          # Put item in list
    return;
  }

=item I<delete>

  method delete(Ref $item)

Deletes the item given by from the collection.

The L</items> in a collection can be accessed via their index location or by
way of the reference to the I<$item>.

When you have a reference to an I<$item> and wish to delete it, you can call
I<delete($item)> directly.

Alternatively, you can use the L</index_of> method to translate the reference
into an I<$index> value and then use L</at_delete>, like this,

  $self->at_delete($self->index_of($item));

After an I<$item> is deleted, L</count> is decremented by 1.

=cut

  method delete(Ref $item) {
    $self->at_delete($self->index_of($item));             # Delete from list
    return;
  }

=item I<delete_all>

  method delete_all()

Deletes all items from the collection.

=cut

  #around delete_all() {
  #  return $self->$next();
  #}

=item I<error>

  method error(Int $code, Int $info)

All collection errors result in a call to I<error>, with error information
passed in I<$code> and I<$info>.

See: I<coXXXX> constants.

=cut

  method error(Int $code, Int $info) {
    $ERRNO = 
        $code == CO_INDEX_ERROR ? -213
      : $code == CO_OVERFLOW    ? -214
      :                           -218
      ;
    confess(
        $code == CO_INDEX_ERROR ?  q{Collection index out of range}
      : $code == CO_OVERFLOW    ?  q{Collection overflow error}
      :                            q{Collection error}
    );
    return;
  }

=item I<first_that>

  method first_that(CodeRef $test) : Ref 

The method I<first_that> is one of the iterator functions and is normally used
to search through the collection for a specific item.

The parameter I<$test> should reference to a caller defined subroutine,
returning true when it matches the search pattern and false (C<undef>)
otherwise.

For each item in the collection until finding a match, I<first_that> calls the
I<$test> function.

=cut

  around first_that(CodeRef $test) {
    return $self->$next(                                  # Return item
      sub { defined && $test->($_) }                      # Test each item
    );
  }

=item I<for_each>

  method for_each(CodeRef $action)

I<for_each> is an iterator function to scan through every item in the
collection, and call the subroutine specified by the I<$action> code reference,
passing to it a reference to each individual item.  

=cut

  method for_each(CodeRef $action) {
    local $_;
    foreach ( @{ $self->items() } ) {                     # Up from first item
      defined && $action->($_);                           # Call with each item
    }
    return;
  }

=item public I<free>

  method free(Ref $item)

This method is similar to L</delete>, except that I<free> weaken all references
of the given I<$item> in the collection.

Free is equivalent to calling,

  $self->delete($item);
  $self->free_item($item);

Although, it is not recommended to call L</free_item> directly.

=cut

  method free(Ref $item) {
    $self->delete($item);                                 # Delete from list
    $self->free_item($item);                              # Free the item
    return;
  }

=item I<free_all>

  method free_all()

Delete each item from the collection and weaken all L</items> references in the
collection.

=cut

  method free_all() {
    while ($self->count > 0) {
      $self->at_free(0);
    }
    return;
  }

=item I<free_item>

  method free_item(Ref $item)

When I<$item> is a reference to an individual item in the collection,
I<free_item($item)> weaken all references of I<$item> in the collection by
calling the core routine I<weaken> exported by L<Scalar::Utils>.

=cut

  method free_item(Ref $item) {
    SET_WEAK_REF:
    foreach ( @{ $self->items() } ) {
      next SET_WEAK_REF
        if !defined
        || isweak($_);

      if ( refaddr($_) == refaddr($item) ) {
        weaken($_);                                       # Weaken of reference
      }
    }
    return;
  }

=item I<get_item>

  method get_item(TStream $s) : Ref

The method I<get_item> is used to read a single collection item from stream
I<$s> and is automatically called by L</load>.

You should not directly call this routine but should use L</load> instead.

By default, I<get_item> calls I<< TStream->get >> to load the item.

=cut

  method get_item(TStream $s) {
    return $s->get();
  }

=item I<index_of>

  method index_of(Ref $item) : Int

Given a reference to an item, I<index_of> returns the index position in the
collection where the I<$item> is located.

Please note, I<index_of> is the opposite of L<at($index)|/at> which returns a
reference to the item.

If I<$item> is not in the collection, I<index_of> returns -1.

=cut

  around index_of(Ref $item) {
    my $item_addr = refaddr($item);
    return -1                                             # Return error index
        if !defined $item_addr
        || $self->count <= 0;                             # Ccount not positive
    return $self->$next(                                  # Return index
        sub { defined && (refaddr($_) == $item_addr) }    # Look for match
    );
  }
 
=item I<insert>

  method insert(Ref $item)

Inserts I<$item> into the collection, and adjusts other indexes if necessary.

=cut

  method insert(Ref $item) {
    $self->at_insert($self->count, $item);                # Insert item
    return;
  }
 
=item I<last_that>

  method last_that(CodeRef $test) : Ref

The method I<last_that> searches backwards through the collection, beginning at
the last item and moving forwards.

For each item, I<last_that> calls the subroutine referenced by I<$test>, until
I<$test> returns a true result, or false (C<undef>) if I<$test> returned false
for all L</items>.

By having I<$test> code reference that makes a comparision between a search
criteria and an item in the collection, you can use I<last_that> to quickly scan
backwards in a collection.

=cut

  around last_that(CodeRef $test) {
    my @found = $self->$next(
      sub { defined && $test->($_) }                      # Test each item
    );
    return pop @found;
  }
 
=item I<pack>

  method pack()

Use I<pack> to eliminate all C<undef> references that may have been stored into
the collection.

=cut

  method pack() {
    # We use the following to filter out the undefined element efficiently
    # without "hardening" any of the references.
    $self->_items(
      sub { \@_ }->( grep defined, @{ $self->items() } )
    );
    return;
  }

=item I<put_item>

  method put_item(TStream $s, Ref $item)

Called by L</store> to write an individual item to stream I<$s>.
By default, I<put_item> calls I<< TStream->put >> to store the item.

=cut

  method put_item(TStream $s, Ref $item) {
    $s->put($item);
    return;
  }

=item I<set_limit>

 mtehod set_limit(Int $a_limit)

Expands or shrinks the collection by changing the memory allocated for L</items>
to handle I<$a_limit> items.

=cut

  method set_limit(Int $a_limit) {
    my $count = $self->count();
    $self->_limit(
        $a_limit < $count              ? $count
      : $a_limit > MAX_COLLECTION_SIZE ? MAX_COLLECTION_SIZE
      : $a_limit == 0                  ? MAX_COLLECTION_SIZE
      :                                  $a_limit
    );
    return;
  }

=item I<store>

  method store(TStream $s)

Writes the entire collection to stream I<$s>.

=cut

  method store(TStream $s) {
    my ($count, $limit, $delta);

    my $write = sub {
      my $type = shift;
      my $value = shift // 0;
      SWITCH: for( $type ) {
        /word/ && $s->write( word($value)->pack, word->size );
      }
    };

    my $do_put_item = sub {
      alias my $p = $_[0];
      $self->put_item($s, $p)                             # Put item on stream
    };
    
    'word'->$write($self->count);                         # Write count 
    'word'->$write($self->limit);                         # Write limit
    'word'->$write($self->delta);                         # Write delta
    $self->for_each($do_put_item);                        # Each item to stream
    return;
  }

=back

=head2 Inheritance

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

2021-2023 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

I<TSortedCollection>, I<TResourceCollection>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
