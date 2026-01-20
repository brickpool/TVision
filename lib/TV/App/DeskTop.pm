package TV::App::DeskTop;
# ABSTRACT: TDeskTop manages the screen area, owning different views.

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TDeskTop
  new_TDeskTop
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  weaken
);

use TV::App::Background;
use TV::App::DeskInit;
use TV::Drivers::Const qw(
  evCommand
);
use TV::Objects::Point;
use TV::Views::Const qw(
  :cmXXXX
  :gfXXXX
  ofTileable
  sfVisible
);
use TV::Views::Group;
use TV::toolkit;

sub TDeskTop() { __PACKAGE__ }
sub name() { 'TDeskTop' }
sub new_TDeskTop { __PACKAGE__->from(@_) }

extends ( TGroup, TDeskInit );

# declare global variables
our $defaultBkgrnd = "\xB0";

# declare attributes
has background        => ( is => 'rw' );
has tileColumnsFirst  => ( is => 'rw', default => sub { !!0 } );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  my $args1 = TGroup->BUILDARGS( @_ );
  my $args2 = TDeskInit->BUILDARGS(
    cBackground => $class->can( 'initBackground' ),
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert ( blessed $self );
  $self->{growMode} = gfGrowHiX | gfGrowHiY;

  if ( $self->{createBackground}
    && ( $self->{background} = $self->createBackground( $self->getExtent() ) ) 
  ) {
    $self->insert( $self->{background} );
  }
  return;
}

sub from {    # $obj ($bounds)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 1 );
  return $class->new( bounds => $_[0] );
}

my $Tileable = sub {    # void ($p)
  my $p = shift;
  return ( $p->{options} & ofTileable ) && ( $p->{state} & sfVisible );
};

my $cascadeNum;
my $lastView;

my $doCount = sub {    # void ($p, @)
  my $p = shift;
  if ( $p->$Tileable() ) {
    $cascadeNum++;
    weaken( $lastView = $p );
  }
  return;
};

my $doCascade = sub {    # void ($p, $r)
  my ( $p, $r ) = @_;
  if ( $p->$Tileable() && $cascadeNum >= 0 ) {
    my $NR = $r;
    $NR->{a}{x} += $cascadeNum;
    $NR->{a}{y} += $cascadeNum;
    $p->locate( $NR );
    $cascadeNum--;
  }
  return;
}; #/ $doCascade = sub

sub cascade {    # void ($r)
  my ( $self, $r ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $r );
  my $min = TPoint->new();
  my $max = TPoint->new();
  $cascadeNum = 0;
  $self->forEach( $doCount, undef );
  if ( $cascadeNum > 0 ) {
    $lastView->sizeLimits( $min, $max );
    if ( ( $min->{x} > $r->{b}{x} - $r->{a}{x} - $cascadeNum )
      || ( $min->{y} > $r->{b}{y} - $r->{a}{y} - $cascadeNum ) )
    {
      $self->tileError();
    }
    else {
      $cascadeNum--;
      $self->lock();
      $self->forEach( $doCascade, $r );
      $self->unlock();
    }
  } #/ if ( $cascadeNum > 0 )
} #/ sub cascade

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );
  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {
      cmNext == $_ and do {
        $self->selectNext( !!0 )
          if $self->valid( cmReleasedFocus );    # <-- Check valid.
        last;
      };
      cmPrev == $_ and do {
        $self->{current}->putInFrontOf( $self->{background} )
          if $self->valid( cmReleasedFocus );    # <-- Check valid.
        last;
      };
      DEFAULT: {
        return;
      }
      $self->clearEvent( $event );
    } #/ SWITCH: for ( $event->{message}...)
  } #/ if ( $event->{what} ==...)
} #/ sub handleEvent

sub initBackground {    # $background ($r)
  my ( $class, $r ) = @_;
  assert ( @_ == 2 );
  assert ( $class );
  assert ( ref $r );
  return TBackground->new( bounds => $r, pattern => $defaultBkgrnd );
}

my ( $numCols, $numRows, $numTileable, $leftOver, $tileNum );

my $iSqr = sub {    # void ($i)
  my $i = shift;
  my ( $res1, $res2 ) = ( 2, int( $i / 2 ) );
  while ( abs( $res1 - $res2 ) > 1 ) {
    $res1 = int( ( $res1 + $res2 ) / 2 );
    $res2 = int( $i / $res1 );
  }
  return $res1 < $res2 ? $res1 : $res2;
};

my $mostEqualDivisors = sub {    # void ($n, $x, $y, $favorY)
  my ( $n, undef, undef, $favorY ) = @_;
  alias: for my $x ( $_[1] ) {
  alias: for my $y ( $_[2] ) {
  my $i = $iSqr->( $n );
  $i++
    if $n % $i != 0 && $n % ( $i + 1 ) == 0;
  $i = int( $n / $i )
    if $i < int( $n / $i );

  if ( $favorY ) {
    $x = int( $n / $i );
    $y = $i;
  }
  else {
    $y = int( $n / $i );
    $x = $i;
  }
  return;
  }} # /alias
}; #/ $mostEqualDivisors = sub

my $doCountTileable = sub {    # void ($p, @)
  my $p = shift;
  $numTileable++
    if $p->$Tileable();
  return;
};

my $dividerLoc = sub {    # $int ($lo, $hi, $num, $pos)
  my ( $lo, $hi, $num, $pos ) = @_;
  return int( ( $hi - $lo ) * $pos / $num + $lo );
};

my $calcTileRect = sub {    # $rect ($pos, $r)
  my ( $pos, $r ) = @_;
  my ( $x, $y );
  my $nRect = TRect->new();

  my $d = ( $numCols - $leftOver ) * $numRows;
  if ( $pos < $d ) {
    $x = int( $pos / $numRows );
    $y = $pos % $numRows;
  }
  else {
    $x = int( ( $pos - $d ) / ( $numRows + 1 ) ) + ( $numCols - $leftOver );
    $y = ( $pos - $d ) % ( $numRows + 1 );
  }
  $nRect->{a}{x} = $dividerLoc->( $r->{a}{x}, $r->{b}{x}, $numCols, $x );
  $nRect->{b}{x} = $dividerLoc->( $r->{a}{x}, $r->{b}{x}, $numCols, $x + 1 );
  if ( $pos >= $d ) {
    $nRect->{a}{y} = $dividerLoc->( $r->{a}{y}, $r->{b}{y}, $numRows + 1, $y  );
    $nRect->{b}{y} = $dividerLoc->( $r->{a}{y}, $r->{b}{y}, $numRows + 1, $y+1);
  }
  else {
    $nRect->{a}{y} = $dividerLoc->( $r->{a}{y}, $r->{b}{y}, $numRows, $y );
    $nRect->{b}{y} = $dividerLoc->( $r->{a}{y}, $r->{b}{y}, $numRows, $y + 1 );
  }
  return $nRect;
}; #/ $calcTileRect = sub

my $doTile = sub {    # void ($p, $r)
  my ( $p, $r ) = @_;
  if ( $p->$Tileable() ) {
    my $rect = $calcTileRect->( $tileNum, $r );
    $p->locate( $rect );
    $tileNum--;
  }
  return;
};

sub tile {    # void ($r)
  my ( $self, $r ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $r );
  $numTileable = 0;
  $self->forEach( $doCountTileable, undef );
  if ( $numTileable > 0 ) {
    $mostEqualDivisors->( $numTileable, $numCols, $numRows,
      !$self->{tileColumnsFirst} );
    if ( ( ( $r->{b}{x} - $r->{a}{x} ) / $numCols == 0 )
      || ( ( $r->{b}{y} - $r->{a}{y} ) / $numRows == 0 ) )
    {
      $self->tileError();
    }
    else {
      $leftOver = $numTileable % $numCols;
      $tileNum  = $numTileable - 1;
      $self->lock();
      $self->forEach( $doTile, $r );
      $self->unlock();
    }
  } #/ if ( $numTileable > 0 )
  return;
} #/ sub tile

sub tileError {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  # Handle tile error
  return;
}

sub shutDown {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $self->{background} = undef;
  $self->SUPER::shutDown();
  return;
}

1

__END__

=pod

=head1 NAME

TV::App::DeskTop - manages the screen area, owning different views.

=head1 DESCRIPTION

Each application has one TDeskTop object, controlled by $deskTop, managing the 
screen area between the menu bar and status line, owning the TBackground and 
other windows/dialogs.

=head1 ATTRIBUTES

=over

=item background

The TBackground object that forms the backdrop of the desktop.

=item tileColumnsFirst

A flag indicating whether tiling should prioritize columns first.

=back

=head1 METHODS

=head2 new

  $deskTop = TDeskTop->new(bounds => $bounds);

Creates a new TDeskTop object with specified bounds.

=head2 cascade

  $self->cascade($r);

Arranges windows in a cascading manner.

=head2 from

  $deskTop = TDeskTop->from($bounds);

Creates a TDeskTop object from specified bounds.

=head2 handleEvent

  $self->handleEvent($event);

Handles events for the TDeskTop object.

=head2 initBackground

  my $background = TDeskTop->initBackground($r);

Initializes the background with specified bounds.

=head2 shutDown

  $self->shutDown();

Shuts down the TDeskTop object.

=head2 tile

  $self->tile($r);

Arranges windows in a tiled manner.

=head2 tileError

  $self->tileError();

Handles errors related to tiling windows.

=cut
