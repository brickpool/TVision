=pod

=head1 NAME

TResourceCollection - Implementing a collections of resources.

=head1 SYNOPSIS

=cut

package TurboVision::Objects::ResourceCollection;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use Function::Parameters {
  before => {
    defaults    => 'method_strict',
    install_sub => 'before',
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
};

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

use TurboVision::Const qw(
  _EMPTY_STRING
  _INT32_T
  _SIMPLE_STR_MAX
  _SIMPLE_STR_T
  _SIZE_OF_INT32
);
use TurboVision::Objects::Common qw(
  byte
  longint
);
use TurboVision::Objects::StreamRec;
use TurboVision::Objects::Stream;
use TurboVision::Objects::StringCollection;
use TurboVision::Objects::Types qw(
  TResourceItem
  TStreamRec
  TStream
  TStringCollection
  TResourceCollection
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

Several specialized collections are derived from I<TCollection>, including
I<TResourceCollection>.

The <TResourceCollection> is used internally to the resource file mechanism and
is not generally used by application programs.

=head2 Class

public class C<< TResourceCollection >>

Turbo Vision Hierarchy

  TObject
    TCollection
      TSortedCollection
        TStringCollection
          TResourceCollection

=cut

package TurboVision::Objects::ResourceCollection {

  extends TStringCollection->class;

  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

  # Private resource record item
  use constant _T_RESOURCE_ITEM =>
      _INT32_T      # Resource position
    . _INT32_T      # Resource size
    . _SIMPLE_STR_T # Resource key
    ;

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => TResourceCollection;

  # ------------------------------------------------------------------------
  # TResourceCollection ----------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item public C<< ScalarRef[SimpleStr] key_of(TResourceItem $item) >>

I<key_of> returns a string reference to the key of the I<$item>.

=cut

  around key_of(TResourceItem $item) {
    return \$item->{key};
  }

=item public C<< TResourceItem get_item(TStream $s) >>

Uses the I<< TStream->read >> function to read a I<TResourceItem> hash from
stream I<$s> and returns a hash reference of type I<TResourceItem>.

=cut

  around get_item(TStream $s) {
    my $pos = do {                                        # Read position
      $s->read(my $buf, longint->size);
      longint( $buf )->unpack() // 0;
    };
    my $size = do {                                       # Read size
      $s->read(my $buf, longint->size);
      longint( $buf )->unpack() // 0;
    };
    my $len = do {                                        # Read key length
      $s->read(my $buf, byte->size);
      byte( $buf )->unpack() // 0;
    };
    my $key = do {                                        # Read string data
      my $buf;
      if ( $len > 0 ) {
        $s->read($buf, $len);
      }
      $buf // _EMPTY_STRING;
    };
    return {                                              # Return reference
      posn  => $pos,                                      # Xfer position
      size  => $size,                                     # Xfer size
      key   => $key,                                      # Xfer string
    };
  }

=item public C<< put_item(TStream $s, TResourceItem $item) >>

By default, writes a hash referenced by I<$item> to the stream I<$s> by
calling I<< TStream->write >>.

=cut

  around put_item(TStream $s, TResourceItem $item) {
    my $buf = pack( _T_RESOURCE_ITEM,
      $item->{posn},
      $item->{size},
      $item->{key},
    );
    $s->write( $buf, length $buf );                       # Write to stream
    return;
  }

=back

=head2 Inheritance

Methods inherited from class C<TStringCollection>

  compare

Methods inherited from class C<TSortedCollection>

  load, index_of, insert, search, store

Methods inherited from class C<TCollection>

  init, at, at_delte, at_free, at_insert, at_put, delete, delete_all, error,
  first_that, for_each, free, free_all, free_item, last_that, pack,
  selt_limit

Methods inherited from class C<Object>

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

I<TStringCollection>, I<TResourceFile>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
