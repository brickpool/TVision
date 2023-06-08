=pod

=head1 NAME

TurboVision::Objects::Types - Types for I<Objects>

=head1 SYNOPSIS

  use TurboVision::Objects::Types;
  ...

=cut

package TurboVision::Objects::Types;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:fpc';

use MooseX::Types::Moose qw( :all );

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use MooseX::Types -declare => [qw(
  FNameStr
  PString
  
  TItemList
  TResourceItem
  TStrIndex
  TStrIndexRec

  TPoint
  TRect
  TStreamRec

  TObject
  TStream
  TDosStream
  TBufStream
  TMemoryStream
  TCollection
  TSortedCollection
  TStringCollection
  TResourceCollection
  TStringList
  TStrListMaker
  TResourceFile
)];
use MooseX::Types::Common::String qw( SimpleStr );
use MooseX::Types::Structured qw( Dict );
use namespace::autoclean;

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 THE TYPES

=head2 Basic Types

=over

=item I<FNameStr>

  subtype FNameStr : Str;

OS file name string.

=cut

subtype FNameStr,
  as Str;

=item I<PString>

  subtype PString : ScalarRef[Str];

Defines a reference to a string.

=cut

subtype PString,
  as ScalarRef[Str];

=item I<TResourceItem>

  subtype TResourceItem : Dict[ posn => Int, size => Int, key => SimpleStr ];

This internal I<Dict> type is used by I<TResourceCollection>.
 
=cut

subtype TResourceItem,
  as Dict[
    posn  => Int,                                         # Resource position
    size  => Int,                                         # Resource size
    key   => SimpleStr,                                   # Resource key
  ];

=item I<TItemList>

  subtype TItemList : ArrayRef[Ref];

This is an internal object type used for maintaining an array of references
in I<TCollection> objects.

=cut

subtype TItemList,
  as ArrayRef[Ref];

=item I<TStrIndexRec>

  subtype TStrIndexRec : Dict[ key => Int, count => Int, offset => Int ];

This internal I<Dict> record type is used by L</TStrIndex>.
 
=cut

subtype TStrIndexRec,
  as Dict[
    key     => Int,
    count   => Int,
    offset  => Int,
  ];

=item I<TStrIndex>

  subtype TStrIndex : ArrayRef[TStrIndexRec];

This internal I<ArrayRef> type of I<TStrIndexRec> is used by I<TStringList> and
I<TStrListMaker>.
 
=cut

subtype TStrIndex,
  as ArrayRef[TStrIndexRec];

=back

=cut

=head2 Object Types

The Objects type hierarchy looks like this

  Moose::Object
    TPoint
    TRect
    TStreamRec
    TObject
      TStream
        TDosStream
          TBufStream
        TMemoryStream
      TCollection
        TSortedCollection
          TStringCollection
            TResourceCollection
      TStringList
      TStrListMaker
      TResourceFile

=cut

class_type TObject, {
  class => 'TurboVision::Objects::Object'
};
class_type TPoint, {
  class => 'TurboVision::Objects::Point'
};
class_type TRect, {
  class => 'TurboVision::Objects::Rect'
};
class_type TStreamRec, {
  class => 'TurboVision::Objects::StreamRec'
};
class_type TStream, {
  class => 'TurboVision::Objects::Stream'
};
class_type TDosStream, {
  class => 'TurboVision::Objects::DosStream'
};
class_type TBufStream, {
  class => 'TurboVision::Objects::BufStream'
};
class_type TMemoryStream, {
  class => 'TurboVision::Objects::MemoryStream'
};
class_type TCollection, {
  class => 'TurboVision::Objects::Collection'
};
class_type TSortedCollection, {
  class => 'TurboVision::Objects::SortedCollection'
};
class_type TStringCollection, {
  class => 'TurboVision::Objects::StringCollection'
};
class_type TResourceCollection, {
  class => 'TurboVision::Objects::ResourceCollection'
};
class_type TStringList, {
  class => 'TurboVision::Objects::StringList'
};
class_type TStrListMaker, {
  class => 'TurboVision::Objects::StrListMaker'
};
class_type TResourceFile, {
  class => 'TurboVision::Objects::ResourceFile'
};

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

L<MooseX::Types>, I<Objects>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
