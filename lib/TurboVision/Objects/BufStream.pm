=pod

=head1 NAME

TBufStream - Implements a buffered version of I<TDosStream>.

=head1 SYNOPSIS

  my $phone_book;
  my $phone_book_file;
  
  package TPersonInfo {
    use Moose;
    use Scalar::Util qw( blessed );
    use TurboVision::Objects;

    extends TCollection->class;
    
    ...
    
    # TPersonInfo is a collection object holding name and
    # address information
    sub store {
      my ($self, $s) = @_;
      confess 'Invalid argument'
        if !blessed($self)
        || !blessed($s);
      s->write_str( $self->name );
      s->write_str( $self->address );
      s->write_str( $self->city );
      s->write_str( $self->state );
      s->write_str( $self->zip );
      s->write_str( $self->age );
    }
    
    # constructor
    sub load {
      my ($class, $s) = @_;
      confess 'Invalid argument'
        if !defined($class)
        || !blessed($s);
      return fail
          ref($class);
      my $name    = s->read_str();
      my $address = s->read_str();
      my $city    = s->read_str();
      my $state   = s->read_str();
      my $zip     = s->read_str();
      my $age     = s->read_str();
      return $class->new(
        name    => $name,
        address => $address,
        city    => $city,
        state   => $state,
        zip     => $zip,
        age     => $age,
      );
    }
  }
  
  ...
  
  # Register the PersonInfo object type
  register_type( RPersonInfo );
  
  # Open the stream file
  $phone_book_file = TBufStream->Init( 'fonebook.dat', ST_CREATE, 1024 );
  
  # Tell the $phone_book collection to put itself to the stream
  $phone_book_file->put( $phone_book );
 
  # The file is closed by the DEMOLISH method
  undef $phone_book_file;

=cut

package TurboVision::Objects::BufStream;

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
use POSIX qw( :errno_h :fcntl_h );

use TurboVision::Const qw( _EMPTY_STRING );
use TurboVision::Objects::Const qw( :stXXXX );
use TurboVision::Objects::Common qw( fail );
use TurboVision::Objects::DosStream;
use TurboVision::Objects::Types qw(
  TDosStream
  TBufStream
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

The I<TBufStream> object type is a derivative of I<TStream> and I<TDosStream>
and is probably the type you will most often use for writing and reading streams
to and from disk files. I<TBufStream> implements a buffered version of
I<TDosStream>, which greatly improves the speed and efficiency of stream
I/O, particularly when writing or reading a lot of small objects.

Generally, you will use the I<< TBufStream-init >> method to open a stream file
for access, the I<< TBufStream->read >> and I<< TBufStream->write >> methods for
performing input and output. For random access streams, you will use
I<< TBufStream->seek >> to position the file pointer to the proper object
reocrd. You may also wish to use I<< TBufStream->flush >> or
<< TBufStream->truncate >>, as appropriate.

=head2 Class

public class C<< TBufStream >>

Turbo Vision Hierarchy

  TObject
    TStream
      TDosStream
        TBufStream

=cut

package TurboVision::Objects::BufStream {

  extends TDosStream->class;

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Attributes

=over

=item public readonly C<< Int buf_end >>

If the buffer is not full, I<buf_end> gives an offset to the last used byte in
the buffer.

=cut

  has 'buf_end' => (
    isa     => Int,
    default => 0,
    writer  => '_buf_end',
  );

=item public readonly C<< Str buffer >>

Stream buffer as byte packed string.

=cut

  has 'buffer' => (
    isa     => Str,
    default => _EMPTY_STRING,
    writer  => '_buffer',
  );

=item public readonly C<< Int buf_ptr >>

An offset from the I<buffer> string indicating the current position.

=cut

  has 'buf_ptr' => (
    isa     => Int,
    default => 0,
    writer  => '_buf_ptr',
  );

=item public readonly C<< Int buf_size >>

The size of the buffer in bytes.

=cut

  has 'buf_size' => (
    isa       => Int,
    default   => 0,
    writer  => '_buf_size',
  );

=begin comment

=item private C<< Int _last_mode >>

I<_last_mode> holds the read or write condition of the last buffer access,
which helps speed up the flush function.

=end comment

=cut

  has '_last_mode' => (
    isa       => Int,
    default   => -1,
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => TBufStream;

=head2 Constructors

=over

=item public C<< TBufStream->init(Str $file_name, Int $mode) >>

Constructs the object and opens the file named in I<$file_name> with access
mode I<$mode> by calling the I<init> constructor inherited from I<TDosStream>.

=cut

  factory_inherit init(Str $file_name, Int $mode, Int $size) {
    my $self = $class->$super($file_name, $mode);         # Call ancestor
    return fail
        if !defined $self;

    alias my $buf_size = $self->{buf_size};               # refer to attributes
    $buf_size = $size;
    return $self;
  }

=begin comment

=item private C<< BUILD(@) >>

Allocates a buffer of I<buf_size> bytes.

Note: The I<BUILD> method is called after the object is constructed.

See also: I<init>

=end comment

=cut

  method BUILD(@) {
    alias my $buffer    = $self->{buffer};                # refer to attributes
    alias my $buf_size  = $self->{buf_size};

    if ( $buf_size ) {
      $buffer = '\0' x $buf_size;
    }
  }
  
=back

=cut

  # ------------------------------------------------------------------------
  # Destructors ------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Destructors

=over

=item public C<< DEMOLISH() >>

Calls I<flush> to flush buffer contents to disk.

=cut

  method DEMOLISH(@) {
    $self->flush();
    return;
  }

=back

=cut

  # ------------------------------------------------------------------------
  # TBufStream -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item public C<< flush() >>

Flushes the stream's buffer provided the stream's status is I<stOK>.

=cut

  method flush() {
    alias my $buf_end = $self->{buf_end};                 # refer to attributes
    alias my $buffer  = $self->{buffer};
    alias my $buf_ptr = $self->{buf_ptr};

    return
        if $self->status != ST_OK
        || !$self->_is_openhandle;
    
    # Must update file?
    if ( $self->_last_mode == O_WRONLY && $buf_ptr > 0 ) {
      # Write to file
      my $num_bytes = syswrite($self->handle, $buffer, $buf_ptr);
      if ( !$num_bytes || $num_bytes != $buf_ptr ) {
        # We have an error
        my $errno = !defined $num_bytes ? POSIX::errno() # Specific write error
                  :                       EFAULT         # Non specific error
                  ;
        $self->error(ST_ERROR, $errno);
      }
    }
    $buf_ptr = 0;                                         # Reset buffer ptr
    $buf_end = 0;                                         # Reset buffer end
    return;
  }
 
=item public C<< read(Item $buf, Int $count) >>

If the stream's status is I<stOK>, reads I<$count> bytes into the I<$buf>.

=cut

  around read($, Int $count) {
    alias my $buf         = $_[-2];                       # refer to parameter
    alias my $position    = $self->{_position};           # refer to attributes
    alias my $stream_size = $self->{_stream_size};
    alias my $buf_end     = $self->{buf_end};
    alias my $buffer      = $self->{buffer};
    alias my $buf_ptr     = $self->{buf_ptr};
    alias my $buf_size    = $self->{buf_size};
    alias my $last_mode   = $self->{_last_mode};

    my ($num_bytes, $amount, $offset);

    $buf = "\0" x $count;                                 # Init clear buffer
    return
      if $self->status != ST_OK
      && !$self->openhandle;                              # File not open

    # Read past stream end?
    if ( $position + $count > $stream_size ) {
      $self->error(ST_READ_ERROR, EFAULT);                # Call stream error
      return;
    }

    # Flush write buffer
    if ( $last_mode == O_WRONLY ) {
      $self->flush();
      # Status still okay?
      return
          if $self->status != ST_OK;
    }
    $last_mode = O_RDONLY;                                # Now set read mode

    $offset = 0;                                          # Transfer offset
    while ( $count > 0 ) {
      # Buffer empty?
      if ( $buf_ptr >= $buf_end ) {
        $amount = $position + $buf_size > $stream_size
                ? $stream_size - $position                # Amount of file left
                : $buf_size                               # Full buffer size
                ;

        # Read from file
        $num_bytes = sysread($self->handle, $buffer, $amount); 
        if ( !$num_bytes || $num_bytes != $amount ) {
          # Error was detected
          $buf = "\0" x $count;
          my $errno
            = !defined $num_bytes ? POSIX::errno()        # Specific read error
            :                       EFAULT                # Non specific error
            ;
          $self->error(ST_READ_ERROR, $errno);
          return;
        }
        $buf_ptr = 0;                                     # Reset buf_ptr
        $buf_end = $num_bytes;                            # End of buffer
      }

      $num_bytes = $buf_end - $buf_ptr;                   # Space in buffer
      $num_bytes = $count if $count < $num_bytes;         # Set transfer size
      {
        local $_
        = substr $buffer, $buf_ptr, $num_bytes;           # Data from buffer
          substr $buf,    $offset,  $num_bytes, $_;
      }
      $count    -= $num_bytes;                            # Reduce count
      $buf_ptr  += $num_bytes;                            # Advance buffer ptr
      $offset   += $num_bytes;                            # Increment offset
      $position += $num_bytes;                            # Adjust position
    }

    return;
  }

=item public C<< seek(Int $pos) >>

Sets the current position to I<$pos> bytes from the beginning of the stream.

=cut

  around seek(Int $pos) {
    alias my $position = $self->{_position};              # refer to attributes

    return                                                # Check status okay
        if $self->status != ST_OK;

    if ( $position != $pos ) {                            # Move required
      $self->flush();                                     # Flush the buffer
      $self->$next($pos);                                 # Call ancestor
    }
    return;
  }

=item public C<< truncate() >>

I<truncate> deletes all data on the calling stream from the current position.

=cut
  
  around truncate() {
    $self->flush();                                       # Flush buffer
    $self->$next();                                       # Truncate file
    return;
  }

=item public C<< write(Str $buf, Int $count) >>

Writes I<$count> bytes from the I<$buf> buffer to the stream, starting at the
current position.

=cut
  
  around write($, Int $count) {
    alias my $buf         = $_[-2];                       # refer to parameter
    alias my $position    = $self->{_position};           # refer to attributes
    alias my $stream_size = $self->{_stream_size};
    alias my $buffer      = $self->{buffer};
    alias my $buf_ptr     = $self->{buf_ptr};
    alias my $buf_size    = $self->{buf_size};
    alias my $last_mode   = $self->{_last_mode};
    confess 'Invalid argument $buf'
      if not is_Str $buf;

    my ($num_bytes, $offset);

    return                                                # Exit if error
        if $self->status != ST_OK
        || !$self->_is_openhandle;                        # File not open

    # Flush read buffer
    if ( $last_mode == O_RDONLY ) {
      $self->flush();
      # Status still okay?
      return
          if $self->status != ST_OK;
    }
    $last_mode = O_WRONLY;                                # Now set write mode

    $offset = 0;                                          # Transfer offset
    while ( $count > 0 ) {
      # Buffer full?
      if ( $buf_ptr >= $buf_size ) {
        # Write to file
        $num_bytes = syswrite($self->handle, $buffer, $buf_size);
        $buf_ptr = 0;                                     # Reset buf_ptr
        if ( !$num_bytes || $num_bytes != $buf_size ) {
          # We have an error
          my $errno
            = !defined $num_bytes ? POSIX::errno()        # Specific read error
            :                       EFAULT                # Unknown write error
            ;
          $self->error(ST_WRITE_ERROR, $errno);
          return;
        }
      }

      $num_bytes = $buf_size - $buf_ptr;                  # Space in buffer
      $num_bytes = $count if $count < $num_bytes;         # Transfer size
      {
        local $_
        = substr $buf,    $offset,  $num_bytes;           # Data ...
          substr $buffer, $buf_ptr, $num_bytes, $_;       # ... to buffer
      }
      $count    -= $num_bytes;                            # Reduce count
      $buf_ptr  += $num_bytes;                            # Advance buffer ptr
      $offset   += $num_bytes;                            # Increment offset

      # Advance position
      $position += $num_bytes;                            # Adjust position
      if ( $position > $stream_size ) {                   # File has expanded
        $stream_size = $position                          # Update new size
      }
    }

    return;
  }

=back

=head2 Inheritance

Methods inherited from class C<TStream>

  copy_from, error, get, get_pos, get_size, put, read_str, reset,
  write_str

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

=head1 CONTRIBUTOR

=over

=item *

2021-2022 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

I<TStream>, I<TDosStream>, I<stXXXX constants>,
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
