package TV::Gadgets::ClockView;
# ABSTRACT: clock view which display the clock

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TClockView
  new_TClockView
);

use POSIX qw( strftime );
use TV::toolkit;
use TV::toolkit::Types qw( :Object );

use TV::Views::DrawBuffer;
use TV::Views::View;

sub TClockView() { __PACKAGE__ }
sub name() { 'TClockView' }
sub new_TClockView { __PACKAGE__->from(@_) }

extends TView;

# private attributes
has lastTime => ( is => 'bare' );
has curTime  => ( is => 'bare' );

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{lastTime} = "        ";
  $self->{curTime}  = "        ";
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my $buf = TDrawBuffer->new();
  my $c   = $self->getColor( 2 );

  $buf->moveChar( 0, ' ', $c, $self->{size}{x} );
  $buf->moveStr( 0, $self->{curTime}, $c );
  $self->writeLine( 0, 0, $self->{size}{x}, 1, $buf );
  return;
} #/ sub draw

sub update {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  $self->{curTime} = strftime( '%H:%M:%S', localtime );

  if ( $self->{lastTime} ne $self->{curTime} ) {
    $self->{lastTime} = $self->{curTime};
    $self->drawView();
  }
  return;
} #/ sub update

1
