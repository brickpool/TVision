package TV::App::Background;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TBackground
  new_TBackground
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );

use TV::App::Const qw( cpBackground );
use TV::Objects::DrawBuffer;
use TV::Views::Const qw( :gfXXXX );
use TV::Views::Palette;
use TV::Views::View;

use TV::toolkit;

sub TBackground() { __PACKAGE__ }
sub new_TBackground { __PACKAGE__->from(@_) }

extends TView;

# declare attributes
has pattern => ( is => 'rw', default => sub { die 'required' } );

sub BUILD {    # void (| \%args)
  my $self = shift;
  assert ( blessed $self );
  $self->{growMode} = gfGrowHiX | gfGrowHiY;
  return;
}

sub from {    # $obj ($bounds, $aPattern)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 2 );
  return $class->new(
    bounds  => $_[0], 
    pattern => $_[1],
  );
}

sub draw {    # void ()
  my $self = shift;
  assert ( blessed $self );
  my $b = TDrawBuffer->new();

  $b->moveChar( 0, $self->{pattern}, $self->getColor(0x01), $self->{size}{x} );
  $self->writeLine( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  return;
}

my $palette;
sub getPalette {    # $palette ()
  my $self = shift;
  assert ( blessed $self );
  $palette ||= TPalette->new(
    data => cpBackground, 
    size => length( cpBackground )
  );
  return $palette->clone();
}

1
