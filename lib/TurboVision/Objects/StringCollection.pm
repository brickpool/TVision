=pod

=head1 NAME

TStringCollection - Implementing a sorted list of strings.

=head1 SYNOPSIS

  my ($word_list, $word_read);
  ...
  $wordlist = TStringCollection->init(10, 5);
  ...
  do {
    ...
    if ( $word_read ) {
      $word_list->insert(\$word_read);
    ...
  } while ( !$word_read );
  ...

=cut

package TurboVision::Objects::StringCollection;

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

use MooseX::Types::Common::String qw( SimpleStr );

use TurboVision::Objects::SortedCollection;
use TurboVision::Objects::Stream;
use TurboVision::Objects::StreamRec;
use TurboVision::Objects::Types qw(
  TSortedCollection
  TStream
  TStreamRec
  TStringCollection
);

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

use Moose::Exporter;
Moose::Exporter->setup_import_methods(
  as_is => [ 'RStringCollection' ],
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<TStringCollection> is a special version of I<TSortedCollection> that is
prebuilt to produce sorted collections of strings.

=head2 Class

public class I<< TStringCollection >>

Turbo Vision Hierarchy

  TObject
    TCollection
      TSortedCollection
        TStringCollection

=cut

package TurboVision::Objects::StringCollection {

  extends TSortedCollection->class;

  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Constants

=over

=item I<RStringCollection>

  constant RStringCollection = < TStreamRec >;

Defining a registration record constant for I<TStringCollection>.

=cut

  use constant RStringCollection => TStreamRec->new(
    obj_type  => 51,
    vmt_link  => __PACKAGE__,
    load      => 'load',
    store     => 'store',
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => __PACKAGE__;

  # ------------------------------------------------------------------------
  # TStringCollection ------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item I<compare>

  around compare(ScalarRef[SimpleStr] $key1, ScalarRef[SimpleStr] $key2) : Int 

Compares I<$$key1> to I<$$key2> as strings and returns C<-1>, C<0> or C<1>.

See I<< TSortedCollection->compare >> for details.

=cut

  around compare(ScalarRef[SimpleStr] $key1, ScalarRef[SimpleStr] $key2) {
    return ${$key1} cmp ${$key2};
  }

=item I<get_item>

  around get_item(TStream $s) : ScalarRef[SimpleStr]

Uses the I<< TStream->read_str >> function to read a string from stream I<$s>
and return a reference to a string containing the result.

=cut

  around get_item(TStream $s) {
    return \$s->read_str();
  }

=item I<put_item>

  around put_item(TStream $s, ScalarRef[SimpleStr] $item)

By default, writes a string referenced by I<$item> to the stream I<$s> by
calling I<< TStream->write_str >>.

=cut

  around put_item(TStream $s, ScalarRef[SimpleStr] $item) {
    $s->write_str( ${$item} );
    return;
  }

=back

=cut

=head2 Inheritance

Methods inherited from class I<TSortedCollection>

  load, index_of, insert, key_of, search, store

Methods inherited from class I<TCollection>

  init, at, at_delte, at_free, at_insert, at_put, delete, delete_all, error,
  first_that, for_each, free, free_all, free_item, last_that, pack,
  selt_limit

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

2021,2023 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

I<TCollection>, I<TSortedCollection>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
