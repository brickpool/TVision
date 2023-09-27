=pod

=head1 NAME

TStringList - Mechanism for accessing strings stored on a stream.

=head1 SYNOPSIS

  my $res_file = TResourceFile->init(
    TBufStream->init('myapp.res', ST_OPEN_READ, l024)
  );
  my $strings = $res_file->get('Strings');

=cut

package TurboVision::Objects::StringList;

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
use MooseX::Types::Common::String qw( is_SimpleStr );
use Try::Tiny;

use TurboVision::Const qw( _EMPTY_STRING );
use TurboVision::Objects::Common qw(
  byte
  fail
  longint
  word
);
use TurboVision::Objects::Const qw( ST_OK );
use TurboVision::Objects::Object;
use TurboVision::Objects::Stream;
use TurboVision::Objects::StreamRec;
use TurboVision::Objects::Types qw(
  TObject
  TStream
  TStreamRec
  TStrIndex
  TStringList
);

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

use Moose::Exporter;
Moose::Exporter->setup_import_methods(
  as_is => [ 'RStringList' ],
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<TStringList> and I<TStrListMaker> are used to create string resource files. 

I<TStringList> should be used in a separate program to create the string
resources, and I<TStringList> should be used to access the previously created
string resources.

Because both objects have the same I<< TStreamRec->obj_type >> value in their
stream registration record, its very important that these object types not
appear in the same program, but should be used in separate programs.

=head2 Class

public class I<< TStringList >>

Turbo Vision Hierarchy

  TObject
    TStringList
    TStrListMaker

=cut

package TurboVision::Objects::StringList {

  extends TObject->class;

  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Constants

=over

=item I<RStringList>

  constant RStringList = < TStreamRec >

I<TStringList> is registered with I<< TStreamRec->register_type(RStringList) >>.

=cut

  use constant RStringList => TStreamRec->new(
    obj_type  => 52,
    vmt_link  => __PACKAGE__,
    load      => 'load',
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------

=begin comment

=item I<_stream>

  has _stream ( is => rw, type => TStream ) = TStream->init();

Hold stream object.

=end comment

=cut

  has '_stream' => (
    is      => 'rw',
    isa     => TStream,
    default => sub { TStream->init() },
  );

=begin comment

=item I<_base_pos>

  has _base_pos ( is => rw, type => Int ) = 0;

Hold position.

=end comment

=cut

  has '_base_pos' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
  );

=begin comment

=item I<_index>

  has _index ( is => rw, type => TStrIndex ) = [];

When loading, it creates an index of a string list and stores it internally so
that L</get> can access the stream later.

=end comment

=cut

  has '_index' => (
    is      => 'rw',
    isa     => TStrIndex,
    default => sub { [] },
  );
  
=begin comment

=item I<_index_size>

  has _index_size ( is => rw, type => Int ) = 0;

Index size.

=end comment

=cut

  has '_index_size' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
  );

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => __PACKAGE__;

=head2 Constructors

=over

=item I<load>

  factory load(TStream $s) : TStringList

Creates and reads the string list index from stream I<$s> and stores internally
a reference to I<$s> so that L</get> can later access the stream when reading
strings.

=cut

  factory load(TStream $s) {
    my $read = sub {
      my $type = shift;
      SWITCH: for( $type ) {
        /longint/ && do {
          $s->read(my $buf, longint->size);
          return longint( $buf )->unpack;
        };
        /word/ && do {
          $s->read(my $buf, word->size);
          return word( $buf )->unpack;
        };
      };
      return undef;
    };

    try {
      my $stream = $s;                                      # Hold stream ref
      my $size = 'word'->$read();                           # Read size
      my $base_pos = $s->get_pos();                         # Hold position
      $s->seek($base_pos + $size);                          # Seek to position
      my $index_size = 'longint'->$read();                  # Read index size
      my $index = [];                                       # Allocate ArrayRef
      READ_INDEX:                                           # Read indexes
      for (0..$index_size-1) {
        my $key     = 'word'->$read() // 0;
        my $count   = 'word'->$read() // 0;
        my $offset  = 'word'->$read() // 0;
        last READ_INDEX if $s->status != ST_OK;
        my $record = {
          key     => $key,
          count   => $count,
          offset  => $offset,
        };
        push @{$index}, $record;
      }
      return $class->new(
        _stream     => $stream,
        _base_pos   => $base_pos,
        _index_size => $index_size,
        _index      => $index,
      );
    }
    catch {
      return fail;
    }
  };

=back

=cut

  # ------------------------------------------------------------------------
  # TStringList ------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item I<get>

  method get(Int $key) : SimpleStr 

The method I<$key> is the primary function used to access individual strings in
the string list.

The I<$key> is a numeric value, typically a predefined constant, used to access
particular strings in the resource file.
 
=cut

  method get(Int $key) {
    alias my $index       = $self->{_index};
    alias my $index_size  = $self->{_index_size};

    my $str;
    READ:
    for my $i (0..$index_size-1) {
      my $record = $index->[$i];
      my $diff = $key - $record->{key};
      if ( $diff < $record->{count} ) {                   # Diff less than count
        $self->_read_str($str, $record->{offset}, $diff); # Read the string
        last READ if $str;
      }
    }
    return $str // _EMPTY_STRING;                         # Return string
  }

=item I<_read_str>

  method _read_str(SimpleStr $s,, Int $offset, Int $skip)

I<TStringList> private method.

=cut

  method _read_str($, Int $offset, Int $skip) {
    alias my $s         = $_[-3];
    alias my $stream    = $self->{_stream};
    alias my $base_pos  = $self->{_base_pos};

    $stream->seek($base_pos + $offset);                   # Seek to position
    READ:
    for (0..$skip) {                                      # One string read
      my $size = do {                                     # Read string size
        $stream->read( my $buf, byte->size );
        byte( $buf )->unpack() // 0;
      };
      next READ if $size == 0;
      $stream->read( $s, $size );                         # Read string data
    }  
    return;
  }

=back

=head2 Inheritance

Methods inherited from class I<TObject>

  init

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

I<TObject>, I<TStrListMaker>,
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
