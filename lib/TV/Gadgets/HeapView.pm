package TV::Gadgets::HeapView;
# ABSTRACT: heap view which display the current heap space

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THeapView
  new_THeapView
);

use PerlX::Assert::PP;
use TV::toolkit;
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw( :Object );

use TV::Views::DrawBuffer;
use TV::Views::View;

sub THeapView() { __PACKAGE__ }
sub name() { 'THeapView' }
sub new_THeapView { __PACKAGE__->from(@_) }

extends TView;

# private attributes
has oldMem  => ( is => 'bare' );
has newMem  => ( is => 'bare' );
has heapStr => ( is => 'bare' );

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{oldMem} = 0;
  $self->{newMem} = $self->heapSize();
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
  $buf->moveStr( 0, $self->{heapStr}, $c );
  $self->writeLine( 0, 0, $self->{size}{x}, 1, $buf );
  return;
} #/ sub draw

sub update {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  if ( ( $self->{newMem} = $self->heapSize() ) != $self->{oldMem} ) {
    $self->{oldMem} = $self->{newMem};
    $self->drawView();
  }
  return;
} #/ sub update

sub heapSize {    # $total ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  if ( $^O eq 'MSWin32' ) {
    require TV::Gadgets::HeapView::Win32;
    goto &TV::Gadgets::HeapView::Win32::heapSize;
  }
  return -1;
}

1
