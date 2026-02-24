package TV::Gadgets::HeapView;
# ABSTRACT: heap view which display the current heap space

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
use Scalar::Util qw( blessed );

use TV::Views::DrawBuffer;
use TV::Views::View;
use TV::toolkit;

sub THeapView() { __PACKAGE__ }
sub name() { 'THeapView' }
sub new_THeapView { __PACKAGE__->from(@_) }

extends TView;

# declare attributes
has oldMem  => ( is => 'bare' );
has newMem  => ( is => 'bare' );
has heapStr => ( is => 'bare' );

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert { blessed $self };
  $self->{oldMem} = 0;
  $self->{newMem} = $self->heapSize();
  return;
}

sub draw {    # void ()
  my ( $self ) = @_;
  assert { @_ == 1 };
  assert { blessed $self };

  my $buf = TDrawBuffer->new();
  my $c   = $self->getColor( 2 );

  $buf->moveChar( 0, ' ', $c, $self->{size}{x} );
  $buf->moveStr( 0, $self->{heapStr}, $c );
  $self->writeLine( 0, 0, $self->{size}{x}, 1, $buf );
  return;
} #/ sub draw

sub update {    # void ()
  my ( $self ) = @_;
  assert { @_ == 1 };
  assert { blessed $self };

  if ( ( $self->{newMem} = $self->heapSize() ) != $self->{oldMem} ) {
    $self->{oldMem} = $self->{newMem};
    $self->drawView();
  }
  return;
} #/ sub update

sub heapSize {    # $total ()
  if ( $^O eq 'MSWin32' ) {
    require TV::Gadgets::HeapView::Win32;
    goto &TV::Gadgets::HeapView::Win32::heapSize;
  }
  return -1;
}

1
