=pod

=head1 NAME

TResourceFile - Implements a stream that can be indexed by key strings.

=head1 SYNOPSIS

  use TurboVision::Objects;
  ...
    my ($res_file, $my_menu);
    
    # construct the menu bar as usual
    $my_menu =  .... 
    $res_file = TResourceFile->Init(
      TBufStream->init( 'menu.sav', ST_CREATE, 1024 )
    );

    # Put the menu bar and name the resource "mainmenu"
    $res_file->put($my_menu, 'mainmenu');

    # Flush and close
    undef $res_file;
  }

=cut

package TurboVision::Objects::ResourceFile;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use constant::boolean;
use Function::Parameters {
  factory_inherit => {
    defaults    => 'method_strict',
    install_sub => 'around',
    shift       => ['$super', '$class'],
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
use MooseX::Types::Common::String qw( SimpleStr );

use TurboVision::Const qw(
  _EMPTY_STRING
  _INT32_T
  _SIZE_OF_UINT16
  _SIZE_OF_INT32
  _UINT16_T
);
use TurboVision::Objects::Common qw(
  fail
  longint
  word
);
use TurboVision::Objects::Object;
use TurboVision::Objects::ResourceCollection;
use TurboVision::Objects::Stream;
use TurboVision::Objects::Types qw(
  TObject
  TResourceCollection
  TResourceFile
  TStream
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<TResourceFile> is a special purpose random access I<TStream> that let's you
find records by a key string instead of a record number.

Using I<TResourceFile>, you can implement simple data base retrievals, as well
as store Turbo Vision components.

B<Commonly Used Features>

In addition to L</init>, L</put> and L</get> are the most frequently used
methods of the I<TResourceFile> object.

=head2 Class

public class I<< TResourceFile >>

Turbo Vision Hierarchy

  TObject
    TResourceFile

=cut

package TurboVision::Objects::ResourceFile {

  extends TObject->class;

  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

  # Private resource manager constants
  use constant _R_STREAM_MAGIC      => 'FBPR';
  use constant _R_STREAM_BACK_LINK  => 'FBBL';
  use constant _R_STREAM_HELP_FILE  => 'FBHF';

  # Private resource manager types
  use constant _T_HEADER =>
      _UINT16_T   # Signature
    .''           # 0:
    .   _UINT16_T #   LastCount
    .   _UINT16_T #   PageCount
    .   _UINT16_T #   ReloCount
    .'X6'         # 1:
    .   _UINT16_T #   InfoType
    .   _INT32_T  #   InfoSize
    ;
  use constant _SIZE_OF_HEADER =>
      _SIZE_OF_UINT16
    + _SIZE_OF_UINT16
    + _SIZE_OF_INT32
    ;
  
  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Attributes

=over

=item I<stream>

  param stream ( is => rwp, type => TStream );

Points to the stream used by this I<TResourceFile> object.

=cut

  has 'stream' => (
    isa       => TStream,
    required  => 1,
    writer    => '_stream',
  );

=item I<modified>

  has modified ( is => rwp, type => Bool ) = !! 0;

If the file has been modified, then this flag is set to true.

The L</flush> method checks this flag to determine if it should update the
resource file.

=cut

  has 'modified' => (
    isa     => Bool,
    writer  => '_modified',
    default => FALSE,
  );

=begin comment

=item I<_base_pos>

  has _base_pos ( is => rw, type => Int ) = 0;

Base position.

=end comment

=cut

  has '_base_pos' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
  );

=begin comment

=item I<_index>

  param _index ( is => rw, type => TResourceCollection );

Index collection.

=end comment

=cut

  has '_index' => (
    is        => 'rw',
    isa       => TResourceCollection,
    handles   => [qw( count )],
    required  => 1,
  );

=begin comment

=item I<_index_pos>

  param _index_pos ( is => rw, type => Int );

Index position.

=end comment

=cut

  has '_index_pos' => (
    is        => 'rw',
    isa       => Int,
    required  => 1,
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => __PACKAGE__;

=head2 Constructors

=over

=item I<init>

  factory init(TStream $a_stream) : TResourceFile

I<< TResourceFile->init >> is called after opening a stream.

The opened stream is passed as a parameter to I<init> and becomes the stream
that holds the resource file.

=cut

  factory_inherit init(TStream $a_stream) {
    my ($stream, $base_pos, $index_pos, $index);
    my ($found, $header);
    
    $found = FALSE;                                      # Preset false
    $stream = $a_stream;                                  # Hold stream
    $base_pos = $stream->get_pos();                       # Get position

    READ:                                                 # Set stop label
    while ( not $found ) {
      # Valid file header?
      last READ if $base_pos+_SIZE_OF_HEADER > $stream->get_size();

      # Seek to position
      $stream->seek($base_pos);

      # Read header
      @{ $header }{qw(
        signature
        last_count
        page_count
        relo_count
        info_type
        info_size
      )}
      = do {
        $stream->read(my $buf, _SIZE_OF_HEADER);
        unpack( _T_HEADER, $buf );
      };

      # Reconstruct the magic string
      my $magic = word( $header->{signature} )->pack()
                . word( $header->{info_type} )->pack();
      if ( $magic eq _R_STREAM_MAGIC ) {
        # Found Resource
        $found = TRUE;
      }
      elsif ( $magic eq _R_STREAM_BACK_LINK ) {
        # Found BackLink
        $base_pos = $header->{info_size} - _SIZE_OF_HEADER;
      }
      elsif ( $magic eq _R_STREAM_HELP_FILE ) {
        # Found HelpFile
        $base_pos = _SIZE_OF_HEADER * 2;
      }
      else {
        # Stop reading
        last READ;
      }
    }

    if ( $found ) {                                       # Resource was found
      $stream->seek($base_pos + _SIZE_OF_HEADER);         # Seek to position
      $index_pos = do {                                   # Read index position
        $stream->read(my $buf, longint->size);          
        longint( $buf )->unpack() // 0;
      };
      $stream->seek($base_pos + $index_pos);              # Seek to resource
      $index = TResourceCollection->load($stream);        # Load resource
    }
    else {
      $index_pos = _SIZE_OF_HEADER + _SIZE_OF_INT32;      # Set index position
      $index = TResourceCollection->init(0, 8);           # Set index

      # Write zero bytes to avoid seek errors when calling put32 & 70.
      if ( $base_pos + $index_pos > $stream->get_size() ) {
        $stream->seek($base_pos);
        my $count = $base_pos + $index_pos - $stream->get_size();
        $stream->write("\0" x $count, $count);
      }
    }
    
    return $class->new(                                   # Initialize object
      stream      => $stream,
      _base_pos   => $base_pos,
      _index_pos  => $index_pos,
      _index      => $index,
    );
  }

=back

=cut

  # ------------------------------------------------------------------------
  # Destructors ------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Destructors

=over

=item I<DEMOLISH>

  method DEMOLISH()

Calls L</flush> and destroys the (private) I<index> collection and the resource
L</stream> file.

=cut

  method DEMOLISH(@) {
    $self->flush();
    return;
  }

=back

=cut


  # ------------------------------------------------------------------------
  # TResourceFile ----------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item I<count>

  method count() : Int

Computes and returns the number of items or resources stored in the file.

=cut

=begin comment

See L</_index>:

  has '_index' => (
    ...
    handles => [qw( count )],
  );

=end comment

=item I<delete>

  method delete(Str $key)

Removes the I<$key> from the index and marks the space it previously occuppied
as being deleted.  

See L</switch_to> for a method to reclaim the now unused space.

=cut

  method delete(Str $key) {
    alias my $modified  = $self->{modified};
          my $index     = $self->_index;

    my $i;
    if ( $index->search(\$key, $i) ) {
      $index->free( $index->at($i) );
      $modified = TRUE;
    }
    return;
  }

=item I<flush>

  method flush()

Checks the L</modified> flag, and if true, updates the resource stream file,
and then resets L</modified> to false.

=cut

  method flush() {
          my $stream    = $self->stream;
          my $base_pos  = $self->_base_pos;
          my $index_pos = $self->_index_pos;
          my $index     = $self->_index;
    alias my $modified  = $self->{modified};
    
    if ( $modified && $stream ) {
      # We have modification
      $stream->seek($base_pos + $index_pos);              # Seek to position
      $index->store($stream);                             # Store the item
      my $res_size = $stream->get_pos() + $base_pos;      # Hold position
      my $link_size = $res_size + _SIZE_OF_HEADER;        # Hold link size
      $stream->write(                                     # Write link back
        _R_STREAM_BACK_LINK,
        length _R_STREAM_BACK_LINK
      );
      $stream->write(                                     # Write link size
        pack(_INT32_T, $link_size),
        _SIZE_OF_INT32
      );
      $stream->seek($base_pos);                           # Move stream position
      $stream->write(                                     # Write magic string
        _R_STREAM_MAGIC,
        length _R_STREAM_MAGIC
      );
      $stream->write(                                     # Write record size
        pack(_INT32_T, $res_size),
        _SIZE_OF_INT32
      );
      $stream->write(                                     # Write index position
        pack(_INT32_T, $index_pos),
        _SIZE_OF_INT32
      );
      $stream->flush();                                   # Flush the stream
    }
    $modified = FALSE;
    return;
  }

=item I<get>

  method get(SimpleStr $key) : Object|Undef

Uses I<$key> as an index into the resource and returns a pointer to the object
that it references, or C<undef> if the I<$key> is not in the file.

See: L</put>

=cut

  method get(SimpleStr $key) {
    my $stream    = $self->stream;
    my $base_pos  = $self->_base_pos;
    my $index     = $self->_index;

    my $i;
    return undef                                          # No match on key
      if !$stream
      || !$index->search(\$key, $i);

    my $posn = $index->at($i)->{posn};
    $stream->seek( $base_pos + $posn );                   # Seek to position
    return $stream->get();                                # Get item
  }

=item I<key_at>

  method key_at(Int $i) : Str

Use I<key_at> to scan through the entire resource file.

The parameter I<$i> is an index to each resource in the file, numbered 0 to
L</count> minus 1.

The method I<key_at> returns the string corresponding to the key value at the
I<$i>'th index position.

=cut

  method key_at(Int $i) {
    return $self->item->at($i)->{key};
  }
 
=item I<put>

  method put(Object $item, Str $key)

Stores the object pointed to by I<$item> into the resource file, using the
specified I<$key>.

See: L</get>

=cut

  method put(Object $item, Str $key) {
          my $stream    = $self->stream;
    alias my $modified  = $self->{modified};
          my $base_pos  = $self->_base_pos;
    alias my $index_pos = $self->{_index_pos};
          my $index     = $self->_index;

    return                                                # Stream not valid
        if !$stream;

    my ($i, $p);
    if ( $index->search(\$key, $i) ) {                    # Search for item
      $p = $index->at($i);
    }
    else {
      $p = {                                              # Allocate hash
        posn  => 0,
        size  => 0,
        key   => _EMPTY_STRING,
      };
      $p->{key} = $key;                                   # Store key
      $index->at_insert($i, $p);                          # Insert item
    }
    if ( $p ) {
      $p->{posn} = $index_pos;                            # Set index position
      $stream->seek( $base_pos + $index_pos );            # Seek file position
      $stream->put($item);                                # Put item on stream
      $index_pos = $stream->get_pos() - $base_pos;        # Hold index position
      $p->{size} = $index_pos - $p->{posn};               # Calc size
      $modified = TRUE;                                  # Set modified flag
    }
    
    return;
  }

=item I<switch_to>

  method switch_to(TStream $a_stream, Bool $pack) : TStream|Undef

Use I<switch_to> to copy the current resource file to another stream specified
by I<$a_stream>.

If I<$pack> is true, I<switch_to> will not copy objects marked as deleted,
thereby compressing the resulting resource file.

See: L</delete>

=cut

  method switch_to(TStream $a_stream, Bool $pack) {
          my $stream    = $self->stream;
    alias my $modified  = $self->{modified};
    alias my $base_pos  = $self->_base_pos;
          my $index_pos = $self->_index_pos;
          my $index     = $self->_index;

    my $new_base_pos;
    
    my $do_copy_ressource = sub {
      my ($item) = @_;
      $stream->seek( $base_pos + $item->{posn} );         # Move stream position
      $item->{posn} = $a_stream->get_pos()                # Hold new position
                      - $new_base_pos;
      $a_stream->copy_from($stream, $item->{size});       # Copy the item
      return;
    };
    
    return undef
        if !$stream;
    return $stream
        if !$a_stream;

    $new_base_pos = $a_stream->get_pos();                 # Get position
    if ( $pack ) {
      my $size = _SIZE_OF_HEADER + _SIZE_OF_INT32;
      $a_stream->seek( $new_base_pos + $size );           # Seek to position
      $index->for_each($do_copy_ressource);               # Copy each resource
      $index_pos = $a_stream->get_pos() - $new_base_pos;  # Hold index position
    }
    else {
      $stream->seek($base_pos);                           # Seek to position
      $a_stream->copy_from($stream, $index_pos);          # Copy the resource
    }
    $stream = $a_stream;                                  # Hold new stream
    $base_pos = $new_base_pos;                            # New base position
    $modified = TRUE;                                    # Set modified flag
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

I<TResourceCollection>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
