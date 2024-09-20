=pod

=head1 NAME

TDosStream - Implements a file stream class

=head1 SYNOPSIS

The use of I<TDosStream> is nearly identical to I<TBufStream>, without the
buffering related methods. See the I<TBufStream> example.

=cut

package TurboVision::Objects::DosStream;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use constant::boolean;
use Function::Parameters {
  factory => {
    defaults    => 'classmethod_strict',
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
use Data::Alias qw( alias );
use IO::File;
use POSIX qw(
  :errno_h
  :fcntl_h
);
use Scalar::Util qw( openhandle );

use TurboVision::Objects::Common qw( fail );
use TurboVision::Objects::Const qw( :stXXXX );
use TurboVision::Objects::Stream;
use TurboVision::Objects::Types qw(
  TDosStream
  TStream
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

Use I<TDosStream> for unbuffered stream file access (see also I<TBufStream>). 
For most applications you will probably prefer to use I<TBufStream> for its
faster, buffered file access.

Generally, you will use the L</init> constructor to open a stream file
for access, the L</read> and L</write> methods for performing input and output.
L</DEMOLISH> will to close the open stream of the object. For random access
streams, you will use L</seek> to position the file pointer to the proper object
record.

=head2 Class

public class I<< TDosStream >>

Turbo Vision Hierarchy

  TObject
     TStream
       TDosStream
          TBufStream

=cut

package TurboVision::Objects::DosStream {

  extends TStream->class;

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Attributes

=over

=item I<handle>

  param handle (
    is        => rwp,
    type      => FileHandle,
    required  => 1,
    predicate => '_is_openhandle',
  );

I<handle> contains the OS file handle used to access the file containing the
stream.

=cut

  has 'handle' => (
    isa       => FileHandle,
    required  => 1,
    writer    => '_handle',
    predicate => '_is_openhandle',
  );

=begin comment

=item I<_stream_size>

  has _stream_size ( is => rw, type => Int, init_arg => 'stream_size' ) = 0;

The size of the stream in bytes.

=end comment

=cut

  has '+_stream_size' => (
    init_arg => 'stream_size',
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

  factory init(Str $file_name, Int $mode) : TDosStream

This constructor creates a OS file stream with the given I<$file_name>. The
I<$mode> argument must be one of the values I<ST_CREATE>, I<ST_OPEN_READ>,
I<ST_OPEN_WRITE>, or I<ST_OPEN>. These constant values are part of the
I<TStream> class.

=cut

  factory init(Str $file_name, Int $mode) {
    my ($size, $status, $errno);
    my $handle = IO::File->new();                         # Create file handle
    return fail
        if !defined $handle;

    # To use the correct mode we must map the TStream mode to Perl's open mode
    my $open_mode = {
      ST_CREATE()     => O_CREAT|O_WRONLY,                # Like Pascal
      ST_OPEN_READ()  => O_RDONLY,
      ST_OPEN_WRITE() => O_WRONLY,
      ST_OPEN()       => O_RDWR,
    }->{ $mode };

    # Handle the mode
    if ( $open_mode ) {
      if ( $handle->open($file_name, $open_mode) ) {      # Set handle value
        $handle->binmode();
        $size   = -s $file_name;                          # Get size of the file
        $status = ST_OK;
        $errno  = 0;
      }
      else {
        $status = ST_INIT_ERROR;                          # Stream error
        $errno  = POSIX::errno();                         # OS error
      }
    }
    else {
      $status = ST_INIT_ERROR;                            # Stream error
      $errno  = EINVAL;                                   # Invalid argument
    }

    return $class->new(
      handle      => $handle,
      stream_size => $size // 0,
      status      => $status,
      error_info  => $errno,
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

  sub DEMOLISH()

Closes the file of the stream object.

=cut

  method DEMOLISH(@) {
    alias my $position = $self->{_position};              # refer position

    if ( !close($self->handle) ) {
      $self->error(ST_ERROR, POSIX::errno());             # Call error routine
    }
    $position = 0;                                        # Zero the position
    return;
  }

=back

=cut


  # ------------------------------------------------------------------------
  # TDosStream -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item I<read>

  around read(Item $buf, Int $count)

Use I<read> to read I<$count> bytes from the stream and into the I<$buf>
parameter. I<read> begins at the stream's current position (as determined by
I<seek> or beginning at the end of the previous I<read> operation).

=cut

  around read($, Int $count) {
    alias my $buf         = $_[-2];                       # refer to parameter
    alias my $position    = $self->{_position};           # refer to attributes
    alias my $stream_size = $self->{_stream_size};
    
    # If there was already an error, or an error was just
    # generated, fill the buffer with "\0"
    $buf = "\0" x $count;                                 # Init clear buffer
    return
        if $self->status != ST_OK
        || !$self->_is_openhandle;

    if ( $position + $count > $stream_size ) {            # Insufficient data
      $self->error(ST_READ_ERROR, EFAULT);                # Read beyond end!!!
      return;
    }

    # Read from file
    my $num_bytes = sysread($self->handle, $buf, $count);
    if ( !$num_bytes || $num_bytes != $count ) {
      # Error was detected
      $buf = "\0" x $count;
      my $errno = !defined $num_bytes
                ? POSIX::errno()                          # Specific read error
                : EBADF                                   # Descriptor is not ..
                ;                                         # .. valid
      $self->error(ST_READ_ERROR, $errno);
      return;
    }

    $position += $num_bytes;                              # Adjust position
    return;
  }

=item I<seek>

  around seek(Int $pos)

Positions the current stream position to I<$pos>. You can use I<seek> to
implement random access to stream files.

=cut

  around seek(Int $pos) {
    alias my $position = $self->{_position};              # refer to attributes

    return                                                # Check status okay
        if $self->status != ST_OK
        || !$self->_is_openhandle;
    
    $pos = 0 if $pos < 0;                                 # Negatives removed
    if ( !defined sysseek($self->handle, $pos, SEEK_SET) ) {
      $self->error(ST_ERROR, ESPIPE);                     # Specific seek error
      return;
    }

    $position = $pos;                                     # Adjust position
    return;
  }

=item I<truncate>

  around truncate()

Use I<truncate> to delete all data following the current position in the
stream.

=cut
  
  around truncate() {
    alias my $position    = $self->{_position};           # refer to attributes
    alias my $stream_size = $self->{_stream_size};

    return                                                # Check status okay
        if $self->status != ST_OK
        || !$self->_is_openhandle;

    # Call seek before truncate to get a defined behavior
    my $pos = sysseek($self->handle, 0, SEEK_CUR);
    if (! $pos ) {
      $self->error(ST_ERROR, ESPIPE);                     # Invalid seek
      return;
    }
    $position = $pos;                                     # Adjust position

    if ( !CORE::truncate($self->handle, $position) ) {
      $self->error(ST_ERROR, EACCES);                     # Permission denied
      return;
    }

    $stream_size = $position;
    return;
  }

=item I<write>

  around write(Str $buf, Int $count)

Use I<write> to copy I<$count> bytes from the I<$buf> parameter to the stream.

=cut

  around write($, Int $count) {
    alias my $buf         = $_[-2];                       # refer arguments
    alias my $position    = $self->{_position};           # refer to attributes
    alias my $stream_size = $self->{_stream_size};
    confess 'Invalid argument $buf'
      if not is_Str $buf;

    return
        if $self->status != ST_OK
        || !$self->_is_openhandle;
    
    # Write to file
    my $num_bytes = syswrite($self->handle, $buf, $count);
    if ( !$num_bytes || $num_bytes != $count ) {
      # Error was detected
      my $errno = !defined $num_bytes
                ? POSIX::errno()                          # Specific read error
                : EBADF                                   # Descriptor is not ..
                ;                                         # .. valid
      $self->error(ST_WRITE_ERROR, $errno);
      $num_bytes //= 0;                                   # Clear bytes moved
    }
    $position += $num_bytes;                              # Adjust position
    if ( $position > $stream_size ) {                     # File expanded
      $stream_size = $position;                           # Adjust stream size
    }
    return;
  }

=begin comment

=item I<_is_openhandle>

  method _is_openhandle() : Bool;

Returns true, if the status is still I<ST_OK> and the I<handle> is open.
Otherwise false is returned.

=end comment

=cut
  
  around _is_openhandle() {
    return FALSE
        if $self->status != ST_OK;

    if ( !$self->$next() || !openhandle $self->handle() ) {
      $self->error(ST_ERROR, EACCES);                     # File open error
      return FALSE;
    }

    return TRUE;
  }

=back

=cut

=head2 Inheritance

Methods inherited from class I<TStream>

  copy_from, error, flush, get, get_pos, get_size, put, read_str, reset,
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

I<TStream>, I<TBufStream>, I<stXXXX constants>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
