=pod

=head1 NAME

TStream - General abstract class providing I/O to and from a storage device.

=head1 SYNOPSIS

See the I<TBufStream> example.

=cut

package TurboVision::Objects::Stream;

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

use Config;
use Data::Alias qw( alias );
use MooseX::ClassAttribute;
use MooseX::Types::Common::String qw( SimpleStr );

use TurboVision::Const qw(
  _EMPTY_STRING
  _STR_T
  _SIMPLE_STR_T
  _UINT16_MAX
);
use TurboVision::Objects::Common qw(
  abstract
  byte
  word
);
use TurboVision::Objects::Const qw( :stXXXX );
use TurboVision::Objects::StreamRec;
use TurboVision::Objects::Types qw(
  TObject
  TStream
  TStreamRec
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<TStream> is the root of the various stream objects. For your applications, you
must use the descendants, I<TDosStream>, I<TBufStream> or I<TMemoryStream>.

=head2 Class

public class I<< TStream >>

Turbo Vision Hierarchy

  TObject
    TStream
      TDosStream
        TBufStream
      TMemoryStream

=cut

package TurboVision::Objects::Stream {

  extends TObject->class;

  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

  # private
  use constant _SIZE_OF_BUFFER => ($] >= 5.014) ? 8192 : 4096;

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Attributes

=head3 Class Attributes

=over

=item public static C<< CodeRef stream_error >>

I<stream_error> allows you to globally override all stream error handling.
For this purpose, an subroutine reference is assigned to the class variable.
A I<TStream> object is passed as a parameter.

  package main;

  TStream->stream_error( sub {
    printf "Catch stream error info #%d\n", shift->error_info
  } );
  ...
  $stream->error(ST_ERROR, 1);  # 'Catch stream error info #1'

=cut

  class_has 'stream_error' => (
    is        => 'rw',
    isa       => CodeRef,
    predicate => 'has_stream_error',
    clearer   => 'clear_stream_error',
  );

=back

=cut

=head3 Object Attributes

=over

=item public C<< Int error_info >>

Whenever an error has occurred (indicated by I<status> != ST_OK), the
I<error_info> attribute contains additional information.

For some values these will be additional I<stXXXX> constants, although for
OS-level file errors, I<error_info> will contain the system errno code (like
C<$!> use).

=cut

  has 'error_info' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
  );

=item public C<< Int status >>

Holds either <ST_OK> or the last error code. See the I<stXXXX> constants for
possible I<status> values.

=cut

  has 'status' => (
    is      => 'rw',
    isa     => Int,
    default => ST_OK,
  );

=begin comment

=item private C<< Int _stream_size >>

The size of the stream in bytes.

=end comment

=cut

  has '_stream_size' => (
    is        => 'rw',
    isa       => Int,
    default   => 0,
    init_arg  => 'undef',
  );

=begin comment

=item private C<< Int _position >>

Current position.

=end comment

=cut

  has '_position' => (
    is        => 'rw',
    isa       => Int,
    default   => 0,
    init_arg  => 'undef',
  );
  
=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => TStream;

  # ------------------------------------------------------------------------
  # TStream ----------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item public C<< copy_from(TStream $s, Int $count) >>

This method copies I<$count> bytes from stream I<$s> to the current stream
object.

=cut

  method copy_from(TStream $s, Int $count) {
    return
        if $self->status != ST_OK;

    my ($buffer, $n);
    while ( $count > 0 ) {
      $n = $count > _SIZE_OF_BUFFER
         ? _SIZE_OF_BUFFER
         : $count
         ;
      $s->read($buffer, $n);
      last if $self->status != ST_OK;
      $self->write($buffer, $n);
      last if $self->status != ST_OK;
      $count -= $n;
    }
    return;
  }

=item public C<< error(Int $code, Int $info) >>

The various stream methods call I<error> when a problem is encountered. 
The method I<error>, in turn, calls the subroutine referenced to the class
variable I<< TStream->stream_error >> (if its not C<undef>).

Once an error condition has been raised, you must call I<reset> before
performing additional stream reads or writes.

=cut

  method error(Int $code, Int $info) {
    $self->status($code);
    $self->error_info($info);
    if ( $self->has_stream_error ) {
      $self->stream_error->( $self );
    }
    return;
  }

=item public C<< flush() >>

I<< TStream->flush >> has no operation, but is overridden in by descendant
objects, such as I<TBufStream>, in order to write the buffer to disk.

=cut

  method flush() {
    return;
  }

=item public C<< Object get() >>

Reads an object from the stream, interpreting the first bytes as the
I<obj_type> attribute of a registeration record.

The I<obj_type> is used to determined exactly what type of object this is, and
then to call that object's I<load> constructor to create a new instance.

The method I<get> returns a refernce to the newly created I<Object>, or C<undef>
on error.

=cut

  method get() {
    return undef
        if $self->status != ST_OK;

    # get object type id
    my $type = do {
      $self->read(my $buf, word->size);
      word( $buf )->unpack() // 0;
    };
    # look for the related entry
    my $rec = TStreamRec->_has_stream_types
            ? TStreamRec->_stream_types
            : undef
            ;
    while ( $rec && $rec->obj_type != $type ) {
      $rec = $rec->has_next
           ? $rec->next
           : undef
           ;
    }

    # Error if no entry found or not valid
    if ( !$rec || !$rec->obj_type || !$rec->vmt_link || !$rec->has_load ) {
      $self->error(ST_GET_ERROR, $rec->obj_type // 0);
      return undef;
    }

    # call the load constructor
    my $class = $rec->vmt_link();
    my $load = $rec->load;
    if ( !defined $load || !$class->can( $load ) ) {
      $self->error(ST_GET_ERROR, $rec->obj_type);
      return undef;
    }
    return $class->$load( $self );
  }
 
=item public C<< Int get_pos() >>

The method I<get_pos> compute the current byte location within the stream.

It returns the stream's current position, or C<-1> on error.

=cut

  method get_pos() {
    alias my $position = $self->{_position};              # refer to attributes

    return $self->status == ST_OK
          ? $position                                     # Return position
          : -1                                            # Stream in error
          ;
  }
 
=item public C<< Int get_size() >>

The method I<get_size> computer the total number of bytes in the stream.

It returns the total size, or C<-1> on error.

=cut

  method get_size() {
    alias my $stream_size = $self->{_stream_size};        # refer to attributes

    return $self->status == ST_OK
          ? $stream_size                                  # Return stream size
          : -1                                            # Stream in error
          ;
  }
 
=item public C<< put(Object $p) >>

Writes the I<obj_type> attribute of the registration record to the stream, and
calls the object's I<store> method to write the appropriate data attributes.

If the object type of I<$p> has not been registered, I<put> calls
I<error> and doesn't write anything to the stream.

=cut

  method put(Object $p) {
    return
        if $self->status != ST_OK;

    # look for the related entry
    my ($rec, $class);
    $rec = TStreamRec->_has_stream_types
         ? TStreamRec->_stream_types
         : undef
         ;
    $class = ref $p;
    while ( $rec && $rec->vmt_link ne $class ) {
      $rec = $rec->has_next
           ? $rec->next
           : undef
           ;
    }

    # Error if no entry found or not valid
    if ( !$rec || !$rec->obj_type || !$rec->has_store ) {
      my $info = $rec
               ? $rec->obj_type
               : 0
               ;
      $self->error(ST_PUT_ERROR, $info);
      return;
    }

    # put object type id
    my $type = $rec->obj_type;
    $self->write(word($type)->pack, word->size);

    # call the related store method
    my $store = $rec->store;
    if ( !defined($store) || !$p->can($store) ) {
      $self->error(ST_PUT_ERROR, $type);
      return;
    }
    $p->$store($self);
    return;
  }

=item public C<< read(Item $buf, Int $count) >>

All descendants of I<TStream> override this procedure to copy I<$count> bytes
from the stream into I<$buf>, and to move the current stream position to the
next object position.

=cut

  method read(Item $buf, Int $count) {
    abstract();
    return;
  }

=item public C<< SimpleStr|Undef read_str() >>

Reads a string from the stream and returns a simple string (a string with less
than 256 characters without any control character) from the current position of
the stream, or C<undef> on error.

This function is used by I<< TStringCollection->get_item >> to read a string
from the stream.

=cut

  method read_str() {
    return undef
        if $self->status != ST_OK;

    my $len = do {
      $self->read(my $buf, byte->size);
      byte( $buf )->unpack() // 0;
    };
    my $p = do {
      my $buf;
      if ( $len > 0 ) {
        $self->read($buf, $len);
      }
      $buf // _EMPTY_STRING;
    };
    return undef
        if $self->status != ST_OK;

    return $p;
  }

=item public C<< reset() >>

Clears any existing error conditions.

=cut

  method reset() {
    $self->status(ST_OK);
    $self->error_info(0);
    return;
  }

=item public C<< seek(Int $pos) >>

The method I<seek> sets the stream's current position to the byte offset
specified by I<$pos>.

=cut

  method seek(Int $pos) {
    alias my $position    = $self->{_position};           # refer to attributes
    alias my $stream_size = $self->{_stream_size};

    return                                                # Check status
        if $self->status != ST_OK;

    $pos = 0 if $pos < 0;                                 # Remove Negatives
    if ( $pos <= $stream_size ) {                         # If valid ...
      $position = $pos;                                   # ... set pos
    }
    else {
      $self->error(TStream->ST_ERROR, $pos);              # Position error
    }
    return;
  }

=item protected C<< Str|Undef str_read() >>

Reads a string from the current position of the calling stream, returning a
C<Str>.

I<returns> C<Str>, or C<undef> on error.

=cut

  method str_read() {
    return undef
        if $self->status != ST_OK;

    my $len = do {
      $self->read(my $buf, word->size);
      word( $buf )->unpack() // 0;
    };
    my $p = do {
      my $buf;
      if ( $len > 0 ) {
        $self->read($buf, $len);
      }
      $buf // _EMPTY_STRING;
    };
    return undef
        if $self->status != ST_OK;

    return $p;
  }
 
=item protected C<< str_write(Str $p) >>

Writes a string I<$p> to the calling stream, starting at the current position.

=cut

  method str_write($) {
    alias my $p = $_[-1];                                 # refer to parameter
    confess 'Invalid argument $p'
      if !is_Str($p)
      || length($p) >= _UINT16_MAX;

    return
        if $self->status != ST_OK;

    my $buf = pack(_STR_T, $p);
    $self->write($buf, length $buf);

    return;
  }

=item public C<< truncate() >>

All descendants must override I<truncate> to delete all data in the stream
after the current position.

=cut
  
  method truncate() {
    abstract();
    return;
  }

=item public C<< write(Str $buf, Int $count) >>

All descendants must override this method to copy I<$count> bytes from I<$buf>
and write them to the stream.

=cut
  
  method write(Str $buf, Int $count) {
    abstract();
    return;
  }

=item public C<< write_str(SimpleStr $p) >>

Outputs a simple string (a string with less than 256 characters without any
control character) I<$p> to the current stream.

=cut

  method write_str(SimpleStr $p) {
    return
        if $self->status != ST_OK;

    if ( $p =~ /\p{XPosixCntrl}/ ) {
      $self->error(ST_WRITE_ERROR, 0);
      return;
    }

    my $buf = pack(_SIMPLE_STR_T, $p);
    $self->write($buf, length $buf);

    return;
  }

=back

=head2 Inheritance

Methods inherited from class C<TObject>

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

I<TDosStream>, I<TBufStream>, I<TMemoryStream>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
