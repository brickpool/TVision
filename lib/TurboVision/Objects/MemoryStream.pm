=pod

=head1 NAME

TMemoryStream - Implements a stream that stores data in memory

=cut

package TurboVision::Objects::MemoryStream;

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

use Data::Alias qw( alias );
use Try::Tiny;

use TurboVision::Const qw( :bool );
use TurboVision::Objects::Const qw( :stXXXX );
use TurboVision::Objects::Common qw( fail );
use TurboVision::Objects::Stream;
use TurboVision::Objects::Types qw(
  TStream
  TMemoryStream
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<TMemoryStream> is a stream that stores its data in dynamic memory.

=head2 Class

public class C<< TMemoryStream >>

Turbo Vision Hierarchy

  TObject
    TStream
      TMemoryStream

=cut

package TurboVision::Objects::MemoryStream {

  extends TStream->class;

  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

  # private
  use constant _MAX_SEG_ARRAY_SIZE => 16384;
  use constant _DEFAULT_BLOCK_SIZE => 0x2000;

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Attributes

=over

=item public readonly C<< Int block_size >>

Memory block size.

=cut

  has 'block_size' => (
    isa     => Int,
    default => _DEFAULT_BLOCK_SIZE,
    writer  => '_block_size',
  );

=item public readonly C<< Int cur_seg >>

Current segment.

=cut

  has 'cur_seg' => (
    isa     => Int,
    default => 0,
    writer  => '_cur_seg',
  );

=item public readonly C<< Int seg_count >>

The number of allocated segments for the stream, with 8K per segment.

=cut

  has 'seg_count' => (
    isa     => Int,
    default => 0,
    writer  => '_seg_count',
  );

=item public readonly C<< ArrayRef[Str] seg_list >>

Memory block list.

=cut

  has 'seg_list' => (
    traits  => ['Array'],
    isa     => ArrayRef[Str],
    default => sub { [] },
    writer  => '_seg_list',
    handles => {
      _clear_seg_list   => 'clear',
      _extend_seg_list  => 'push',
      _reduce_seg_list  => 'splice',
    },
  );

=item public C<< Int position >>

The current position within the stream.

=cut

  has '+_position' => (
    init_arg  => 'position',
  );
  # alias   => 'position',
  sub position { goto &_position }

=item public C<< Int size >>

The size of the stream in bytes.

=cut

  has '+_stream_size' => (
    init_arg  => 'size',
  );
  # alias   => 'size',
  sub size { goto &_stream_size }

=begin comment

=item private C<< Int _mem_size >>

Memory alloc size in bytes.

=end comment

=cut

  has '_mem_size' => (
    is        => 'rw',
    isa       => Int,
    init_arg  => undef,
    default   => 0,
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => TMemoryStream;

=head2 Constructors

=over

=item public C<< TMemoryStream->init(Int $a_limit, Int $a_block_size) >>

This Constructor creates an memory stream with the given minimum size in bytes.
Calls the I<init> constructor inherited from I<TStream>, then sets I<block_size>
and alocate the memory.

=cut

  factory_inherit init(Int $a_limit = 0, Int $a_block_size = 0) {
    my $self = $class->$super();                          # Call ancestor
    return fail
        if !defined $self;

    alias my $blk_size    = $self->{block_size};          # refer to attributes
          my $limit;

    $blk_size = $a_block_size
              ? $a_block_size                             # Set blocksize
              : _DEFAULT_BLOCK_SIZE                       # Default blocksize
              ;

    $limit = $a_limit
           ? int(($a_limit + $blk_size-1) / $blk_size)    # Blocks needed
           : 1                                            # At least 1 block
           ;

    if ( !$self->_change_list_size($limit) ) {            # Try allocate blocks
      $self->error(ST_INIT_ERROR, 0);                     # Initialize error
    }

    return $self;
  }

=back

=cut


  # ------------------------------------------------------------------------
  # TMemoryStream ----------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item public C<< read(Item $buf, Int $count) >>

Reads I<$count> bytes from the stream, starting at the current position, into
the I<$buf> buffer.

=cut

  around read($, Int $count) {
    alias my $buf         = $_[-2];                       # refer to parameter
    alias my $blk_size    = $self->{block_size};          # refer to attributes
    alias my $cur_block   = $self->{cur_seg};
    alias my $position    = $self->{_position};
    alias my $stream_size = $self->{_stream_size};

    my ($offset, $block_pos, $amount);

    $buf = "\0" x $count;                                 # Init clear buffer
    return
        if $self->status != ST_OK;
    
    if ( $position + $count > $stream_size ) {
      $self->error(ST_READ_ERROR, 0);
      return;
    }

    $offset = 0;                                          # Transfer offset
    while ( $count > 0 ) {
      $cur_block = int($position / $blk_size);            # Current block
      $block_pos = $position - $cur_block * $blk_size;    # Current position
      $amount = $blk_size - $block_pos;                   # Current block space
      $amount = $count if $amount > $count;               # Adjust read size

      # Move data to buffer
      try {
        alias my $seg = $self->seg_list->[$cur_block];
        local $_
        = substr $seg, $block_pos, $amount;
          substr $buf, $offset,    $amount, $_;
      }
      catch {
        $buf = "\0" x $count;
        $self->error(ST_READ_ERROR, 0);                   # Move failed
        return;
      };

      $position += $amount;                               # Adjust position
      $offset += $amount;
      $count -= $amount;                                  # Adjust count left
    }

    return;
  }

=item public C<< truncate() >>

I<truncate> deletes all data on the calling stream from the current position.

=cut
  
  around truncate() {
    alias my $blk_size    = $self->{block_size};          # refer to attributes
    alias my $position    = $self->{_position};    
    alias my $stream_size = $self->{_stream_size};
    my ($limit);
    
    return                                                # Check status okay
        if $self->status != ST_OK;

    $limit = $position                                    # Blocks needed
           ? int(($position + $blk_size-1) / $blk_size)
           : 1                                            # At least one block
           ;

    if ( $self->_change_list_size($limit) ) {
      $stream_size = $position;                           # Set stream size
    }
    else {
      $self->error(ST_ERROR, 0);                          # Error truncating
    }
       
    return;
  }

=item public C<< write(Str $buf, Int $count) >>

Writes I<$count> bytes from the I<$buf> buffer to the stream, starting at the
current position.

=cut

  around write($, Int $count) {
    alias my $buf         = $_[-2];                       # refer arguments
    alias my $blk_size    = $self->{block_size};          # refer to attributes
    alias my $cur_block   = $self->{cur_seg};
    alias my $position    = $self->{_position};    
    alias my $stream_size = $self->{_stream_size};
    alias my $mem_size    = $self->{_mem_size};
    confess 'Invalid argument $buf'
      if not is_Str $buf;

    my ($offset, $block_pos, $amount);

    return
        if $self->status != ST_OK;
    
    if ( $position + $count > $mem_size ) {               # Expansion needed
      my $limit = $position + $count
                ? int(($position + $count + $blk_size-1) / $blk_size)
                : 1                                       # At least 1 block
                ;
      if ( !$self->_change_list_size($limit) ) {
        $self->error(ST_WRITE_ERROR, 0);                  # Expansion failed!!!
        return;
      }
    }

    $offset = 0;                                          # Transfer offset
    while ( $count > 0 ) {
      $cur_block = int($position / $blk_size);            # Current segment
      $block_pos = $position - $cur_block * $blk_size;    # Current position
      $amount = $blk_size - $block_pos;                   # Current block space
      $amount = $count if $amount > $count;               # Adjust write size

      # Transfer data
      try {
        alias my $seg = $self->seg_list->[$cur_block];
        local $_
        = substr $buf, $offset,    $amount;
          substr $seg, $block_pos, $amount, $_;
      }
      catch {
        $self->error(ST_WRITE_ERROR, 0);                  # Move failed
        return;
      };

      $position += $amount;                               # Adjust position
      $offset += $amount;
      $count -= $amount;                                  # Adjust count left
      if ( $position > $stream_size ) {                   # File expanded
        $stream_size = $position;                         # Adjust stream size
      }
    }
    
    return;
  }

=begin comment

=item private C<< Int _change_list_size(Int $a_limit) >>

Allocate or deallocate blocks in I<seg_list>.

=end comment

=cut

  method _change_list_size(Int $a_limit) {
    alias my $blk_size  = $self->{block_size};            # refer to attributes
    alias my $blk_count = $self->{seg_count};
    alias my $mem_size  = $self->{_mem_size};

    $a_limit = 0 if $a_limit < 0;                         # Negatives removed
    if ( $a_limit > _MAX_SEG_ARRAY_SIZE ) {
      return _FALSE;                                      # To many blocks req
    }
    elsif ( $a_limit == $blk_count ) {
      return _TRUE;                                       # No change
    }
    elsif ( $a_limit == 0 ) {
      $self->_clear_seg_list();                           # Clear the block list
    }
    elsif ( $a_limit < $blk_count ) {
      $self->_reduce_seg_list( $a_limit - $blk_count );   # Shrink block list
    }
    elsif ( $a_limit > $blk_count ) {
      my $get_mem = "\0" x $blk_size;                     # Allocate memory
      $self->_extend_seg_list(                            # Expand block list
        ($get_mem) x ($a_limit - $blk_count)
      );
    }
    $blk_count = $a_limit;                                # Hold new count
    $mem_size = $blk_count * $blk_size;                   # Set memory size

    return _TRUE;                                         # Successful
  }

=back

=head2 Inheritance

Methods inherited from class C<TStream>

  copy_from, error, flush, get, get_pos, get_size, put, read_str, reset, seek,
  write_str

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

2021-2022 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

I<TStream>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
