package TV::TextView::TextDevice;
# ABSTRACT: Abstract text device class

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TTextDevice
  new_TTextDevice
);

require bytes;
use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Views::Scroller;
use TV::toolkit;

sub TTextDevice() { __PACKAGE__ }
sub name() { 'TTextDevice' }
sub new_TTextDevice { __PACKAGE__->from(@_) }

extends TScroller;

# declare attributes
has egress    => ( is => 'bare' );
has esize     => ( is => 'bare' );
has autoflush => ( is => 'bare' );
has opened    => ( is => 'ro' );

# predeclare private methods
my (
  $append_to_egress
);

# TTextDevice streambuf interface

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_ );
  my $args2 = check( {
    # set 'default' values, init_args => undef,
    egress    => { default => '',   no_override => 1 },
    esize     => { default => 2048, no_override => 1 },
    autoflush => { default => !!0,  no_override => 1 },
    opened    => { default => !!1,  no_override => 1 },
  } => { @_ } ) || Carp::confess( last_error );
  return { %$args1, %$args2 };
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  unless ( $in_global_destruction ) {
    $self->close()
      if $self->opened();
  }
  return;
}

sub do_sputn {    # $num ($s, $count)
  my ( $self, $s, $count ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( defined $s and !ref $s );
  assert ( looks_like_number $count );
  ...
}

# B<Note>: only for compatibility
sub overflow {    # $int (|$c)
  my ( $self, $c ) = @_;
  assert ( @_ >= 1 && @_ <= 2 );
  assert ( blessed $self );
  assert ( !defined $c or looks_like_number $c );
  $c //= -1;
  if ( $c != -1 ) {
    my $b = chr( $c );
    $self->do_sputn( $b, 1 );
  }
  return 1;
}

# IO::Handle interface

# C<autoflush> getter/setter
# B<Note>: turn on autoflush if no argument is given.
sub autoflush {    # $ (|$)
  my ( $self, $value ) = @_;
  assert ( @_ >= 1 && @_ <= 2 );
  assert ( blessed $self );
  assert ( !defined $value or !ref $value );
  my $r = $self->{autoflush};
  $self->{autoflush} = !!( @_ > 1 ? $value : 1 );
  return $r;
}

sub close {    # $success ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  return unless $self->opened();
  my $r = $self->flush();
  $self->{opened} = !!0;
  return $r;
}

# C<flush> method: write buffer and clear it.
# Returns C<"0 but true"> on success, undef on error.
sub flush {    # $success ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  return 1 unless length $self->{egress};    # Nothing to flush
  my $data = $self->{egress};
  $self->{egress} = '';                      # Clear buffer
  return $self->syswrite( $data ) ? "0E0" : undef;
}

# Append data to the C<egress> buffer and L</flush> if size exceeds C<esize>
$append_to_egress = sub {    # void ($data)
  my ( $self, $data ) = @_;
  $self->{egress} .= $data;

  # Auto-flush if buffer exceeds esize
  if ( bytes::length( $self->{egress} ) >= $self->{esize} ) {
    $self->flush();
  }
  return;
};

sub print {    # $success (@list)
  my ( $self, @list ) = @_;
  assert ( @_ >= 2 );
  assert ( blessed $self );
  assert ( scalar @list );
  $self->$append_to_egress( join( '', @list ) );
  $self->flush() if $self->{autoflush};
  return 1;
}

sub printf {   # $success ($format, @list)
  my ( $self, $format, @list ) = @_;
  assert ( @_ >= 2 );
  assert ( blessed $self );
  assert ( defined $format and !ref $format );
  $self->$append_to_egress( sprintf( $format, @list ) );
  $self->flush() if $self->{autoflush};
  return 1;
}

sub printflush {    # $success (@list)
  my ( $self, @list ) = @_;
  assert ( @_ >= 2 );
  assert ( blessed $self );
  assert ( scalar @list );
  $self->$append_to_egress( join( '', @list ) );
  return $self->flush();    # Force flush right now
}

sub say {    # $success (@list)
  my ( $self, @list ) = @_;
  assert ( @_ >= 2 );
  assert ( blessed $self );
  assert ( scalar @list );
  $self->$append_to_egress( join( '', @list ) . "\n" );
  $self->flush() if $self->{autoflush};
  return 1;
}

# The C<syswrite> method in Perl is the equivalent of L</do_sputn> in
# Borland's RTL. We need to call L</do_sputn> here to replicate the original 
# behavior.
sub syswrite {    # $num|undef ($, |$length, |$offset)
  my ( $self, $s, $len, $off ) = @_;
  assert ( @_ >= 2 &&  @_ <= 4 );
  assert ( blessed $self );
  assert ( defined $s and !ref $s );
  assert ( !defined $len or looks_like_number $len );
  assert ( !defined $off or looks_like_number $off );
  $len //= bytes::length( $s );
  return $self->do_sputn(
    (
      defined( $len )
        ? bytes::substr( $s, $off || 0, $len )
        : $s
    ),
    $len
  );
} #/ sub syswrite

# always true

sub eof          { 1 }
sub ungetc       { 1 }
sub binmode      { 1 }

# always false

sub getc         { '' }
sub read         { '' }
sub error        { '' }
sub getline      { '' }

# abstract

sub new_from_fd  { ... }
sub fdopen       { ... }
sub fcntl        { ... }
sub format_write { ... }
sub ioctl        { ... }
sub stat         { ... }
sub truncate     { ... }
sub seek         { ... }
sub tell         { ... }
sub sync         { ... }
sub blocking     { ... }
sub sysseek      { ... }

# stubs for the other methods

sub write        { !!shift->syswrite(@_) }
sub getlines     { wantarray ? () : Carp::croak('called in a scalar context') }
sub fileno       { -1 }
sub clearerr     { 0 }
sub sysread      { 0 }

# tiehandle interface

sub TIEHANDLE { 
  ref($_[0]) 
    ? shift 
    : shift->new(@_)
}

sub GETC    { shift->getc(@_)     }
sub PRINT   { shift->print(@_)    }
sub PRINTF  { shift->printf(@_)   }
sub READ    { shift->read(@_)     }
sub WRITE   { shift->syswrite(@_) }
sub SEEK    { shift->seek(@_)     }
sub TELL    { shift->tell(@_)     }
sub EOF     { shift->eof()        }
sub CLOSE   { shift->close(@_)    }
sub BINMODE { shift->binmode(@_)  }

sub READLINE {
  wantarray 
    ? shift->getlines(@_) 
    : shift->getline(@_) 
}

1

__END__

=head1 NAME

TV::TextView::TextDevice - Abstract text device class

=head1 DESCRIPTION

C<TTextDevice> is an abstract base class for text-based devices in Turbo Vision.
It represents a scrollable, TTY-like text view and serves as a foundation for
implementing real terminal drivers.

In addition to the fields and methods inherited from C<TScroller>, 
C<TTextDevice> defines virtual methods for reading and writing strings to and 
from the device. The class itself does not implement any concrete device 
functionality but provides IO::Handle methods an a tie handle interface for 
derived classes that represent actual terminal or text output devices.

C<TTextDevice> uses the constructor of C<TScroller> and extends it with 
features such as buffer management, L</autoflush>, and a simple interface for 
output operations (e.g., L</print>, L</printf>, L</say>).

Typical use cases include:

=over

=item Deriving custom terminal drivers

=item Implementing text-based output devices for scrollable views

=back

=head1 METHODS

=head2 new_TTextDevice

  my $device = new_TTextDevice($bounds, $aHScrollBar, $aVScrollBar);

Factory constructor for creating a new C<TTextDevice> object.

=head2 autoflush

 my $scalar = $self->autoflush( | $scalar);

Gets or sets the autoflush flag; enables autoflush if called without arguments.

=head2 binmode

 my $success = $self->binmode( | $layer);

Sets the device to binary mode (no effect in this implementation, always return 
I<true> for this class).

=head2 blocking

 my $bool | undef = $self->blocking( | $bool);

Stub method for enabling or disabling blocking mode.

=head2 clearerr

 my $scalar = $self->clearerr();

Clears any error state (No-op, always return returns I<0> for this class).

=head2 close

 my $success = $self->close();

Closes the device and flushes any remaining data.

=head2 do_sputn

 my $num = $self->do_sputn($s, $count);

Writes a string of a given length to the device buffer. Abstract method, must 
be overridden by a derived class.

=head2 eof

 my $bool = $self->eof();

Indicates end-of-file (No-op, always return I<true> for this class).

=head2 error

 my $bool = $self->error();

Returns the error state (No-op, always return I<false> for this class).

=head2 fcntl

 my $success = $self->fcntl($function, $scalar);

Stub method for file control operations.

=head2 fdopen

 my $success = $self->fdopen($fd, $mode);

Stub method for opening a file descriptor.

=head2 fileno

 my $fd = $self->fileno();

Returns the file descriptor number (No-op, always return C<-1> for this class).

=head2 flush

 my $success | undef = $self->flush();

Writes the buffer to the device and clears it.

Returns C<"0 but true"> on success, C<undef> on error.

=head2 format_write

 $self->format_write($expr);

Stub method for formatted output.

=head2 getc

 my $char = $self->getc();

Reads a single character (No-op, always return I<empty> for this class).

=head2 getline

 my $line | undef = $self->getline();

Reads a line from the device (No-op, always return I<empty> for this class).

=head2 getlines

 my @lines = $self->getlines();

Reads all lines from the device (No-op, always return I<empty> for this class). 
Croaks in scalar context.

=head2 ioctl

 my $success = $self->ioctl($function, $scalar);

Stub method for device control operations.

=head2 name

 my $name = $self->name();

Returns the name of the class (C<"TTextDevice">).

=head2 new_from_fd

 my $term = $self->new_from_fd();

Stub method for creating an object from a file descriptor (always return 
C<undef> for this class).

=head2 overflow

 my $int = $self->overflow( | $c);

Writes a single character to the device (only for compatibility).

=head2 print

 my $success = $self->print(@list);

Appends data to the buffer (using L</syswrite> internally).

=head2 $self->printf

 my $success = $self->printf($format, @list);

Formats and appends data to the buffer (using L</syswrite> internally).

=head2 printflush

 my $success = $self->printflush(@list);

Appends data to the buffer and forces an immediate flush (using L</syswrite> 
internally).

=head2 read

 my $num = $self->read($buf, $len, | $offset);

Reads data from the device (No-op, always return I<empty> for this class).

=head2 say

 my $success = $self->say(@list);

Appends data followed by a newline (using L</syswrite> internally).

=head2 seek

 my $success = $self->seek($position, $whence);

Stub method for seeking within the device.

=head2 stat

 my @list = $self->stat();

Stub method for retrieving device statistics.

=head2 sync

 my $success = $self->sync();

Stub method for synchronizing the device.

=head2 sysread

 my $num = $self->sysread($buf, $len, | $offset);

Stub method for reading raw data (always returns C<0> for this class).

=head2 sysseek

 my $success = $self->sysseek($position, $whence);

Stub method for seeking using system calls.

=head2 syswrite

 my $num | undef = $self->syswrite($scalar, | $length, | $offset);

Writes raw data to the device using C<do_sputn> internally.

B<Note>: The C<syswrite> method in Perl is the equivalent of L</do_sputn> in
Borland's RTL. We need to call L</do_sputn> here to replicate the original
behavior.

=head2 tell

 my $pos = $self->tell();

Stub method for returning the current position.

=head2 truncate

 my $success = $self->truncate($length);

Stub method for truncating the device.

=head2 ungetc

 my $success = $self->ungetc($ord);

Pushes a character back into the input stream (No-op, always return I<true> for 
this class).

=head2 write

  my $success = $self->write($buf, $len | $offset);

Writes data to the device using L</syswrite> internally.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
