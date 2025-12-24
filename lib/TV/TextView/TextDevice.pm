package TV::TextView::TextDevice;
# ABSTRACT: Abstract text device object

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

has io => ( id => 'bare' );

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  $self->close() if $self->opened();
  return;
}

# only for compatibility
sub do_sputn {    # $int ($s, $count)
  my ( $self, $s, $count ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( defined $s and !ref $s );
  assert ( looks_like_number $count );
  ...
}

# only for compatibility
sub overflow {    # $int ($c)
  my ( $self, $c ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $c );
  if ( $c != -1 ) {
    my $b = chr( $c );
    $self->do_sputn( $b, 1 );
  }
  return 1;
}

# IO::Handle interface
my $abstract = sub { ... };

*open = $abstract;

sub close {
  my $self = shift;
  assert ( blessed $self and $self->{io} );
  $self->{io}->close();
}

sub opened {
  my $self = shift;
  assert ( blessed $self and $self->{io} );
  $self->{io}->opened(@_);
}

*binmode = $abstract;

sub getc {
  my $self = shift;
  assert ( blessed $self and $self->{io} );
  $self->{io}->getc(@_);
}

sub ungetc {
  my $self = shift;
  assert ( blessed $self and $self->{io} );
  $self->{io}->ungetc(@_);
}

sub eof {
  my ( $self )= @_;
  assert ( @_ == 1 );
  assert ( blessed $self and $self->{io} );
  $self->{io}->eof();
}

sub print {
  my $self = shift;
  assert ( blessed $self and $self->{io} );
  $self->{io}->print(@_);
}

sub printf {
  my $self = shift;
  assert ( blessed $self and $self->{io} );
  $self->{io}->printf(@_);
}

sub seek {
  my $self = shift;
  assert ( blessed $self and $self->{io} );
  $self->{io}->seek(@_);
}

*sysseek = \&seek;

sub tell {
  my $self = shift;
  assert ( blessed $self and $self->{io} );
  $self->{io}->tell(@_);
}

sub getline {
  my $self = shift;
  assert ( blessed $self and $self->{io} );
  $self->{io}->getline(@_);
}

sub getlines {
  my $self = shift;
  assert ( blessed $self and $self->{io} );
  $self->{io}->getlines(@_);
}

sub truncate {
  my $self = shift;
  assert ( blessed $self and $self->{io} );
  $self->{io}->truncate(@_);
}

sub read {
  my $self = shift;
  assert ( blessed $self and $self->{io} );
  $self->{io}->read(@_);
}

*write    = $abstract;
*binmode  = $abstract;

*sysread  = \&read;
*syswrite = \&write;

*stat      = $abstract;
*blocking  = $abstract;
*fileno    = $abstract;
*error     = $abstract;
*clearerr  = $abstract; 
*sync      = $abstract;
*flush     = $abstract;
*setbuf    = $abstract;
*setvbuf   = $abstract;
*untaint   = $abstract;
*autoflush = $abstract;
*fcntl     = $abstract;
*ioctl     = $abstract;

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
