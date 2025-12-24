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

has data => ( id => 'bare', default => sub { '' } );
has io   => ( id => 'bare' );

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  open( $self->{io}, '+>', \$self->{data} );
  return;
} #/ sub new

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  $self->{io}->close() if $self->{io}->opened();
  return;
}

# only for compatibility
sub do_sputn {    # $int ($s, $count)
  my ( $self, $s, $count ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( defined $s and !ref $s );
  assert ( looks_like_number $count );
  ...;
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

# tiehandle interface
sub TIEHANDLE { 
  ref($_[0]) 
    ? shift 
    : shift->new(@_)
}

sub GETC    { shift->{io}->getc(@_) }
sub PRINT   { shift->{io}->print(@_) }
sub PRINTF  { shift->{io}->printf(@_) }
sub READ    { shift->{io}->read(@_) }
sub WRITE   { ... }
sub SEEK    { shift->{io}->seek(@_) }
sub TELL    { shift->{io}->tell(@_) }
sub EOF     { shift->{io}->eof() }
sub CLOSE   { shift->{io}->close(@_) }
sub BINMODE { shift->{io}->binmode(@_) }

sub READLINE {
  wantarray 
    ? shift->{io}->getlines(@_) 
    : shift->{io}->getline(@_) 
}

1
