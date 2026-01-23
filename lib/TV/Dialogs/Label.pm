package TV::Dialogs::Label;
# ABSTRACT: TLabel provide a description for another dialog control.

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TLabel
  new_TLabel
);

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
  weaken
);

use TV::Dialogs::Const qw( cpLabel );
use TV::Dialogs::StaticText;
use TV::Dialogs::Util qw( hotKey );
use TV::Drivers::Const qw(
  :evXXXX
);
use TV::Drivers::Util qw(
  cstrlen
  getAltCode
);
use TV::Views::Const qw(
  cmReceivedFocus
  cmReleasedFocus
  :ofXXXX
  phPostProcess
  sfFocused
);
use TV::Views::DrawBuffer;
use TV::Views::Palette;
use TV::Views::View;
use TV::toolkit;

sub TLabel() { __PACKAGE__ }
sub name() { 'TLabel' }
sub new_TLabel { __PACKAGE__->from(@_) }

extends TStaticText;

# import global variables
use vars qw(
  $showMarkers
  $specialChars
);
{
  no strict 'refs';
  *showMarkers  = \${ TView . '::showMarkers' };
  *specialChars = \${ TView . '::specialChars' };
}

# declare attributes
has link  => ( is => 'ro' );
has light => ( is => 'ro' );

# predeclare private methods
my (
  $focusLink,
);

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_ );
  my $args2 = check( {
    link => { required => 1, allow => sub { !defined $_[0] or blessed $_[0] } },
    light => { default => !!0, no_override => 1 },
  } => { @_ } ) || Carp::confess( last_error );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert ( blessed $self );
  weaken( $self->{link} ) if $self->{link};
  $self->{options} |= ofPreProcess | ofPostProcess;
  $self->{eventMask} |= evBroadcast;
  return;
} #/ sub BUILD

sub from {    # $obj ($bounds, $aText, $aLink)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 3 );
  return $class->new( bounds => $_[0], text => $_[1], link => $_[2] );
}

sub shutDown {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $self->{link} = undef;
  return;
}

sub draw {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  my $color;
  my $b = TDrawBuffer->new();
  my $scOff;

  if ( $self->{light} ) {
    $color = $self->getColor( 0x0402 );
    $scOff = 0;
  }
  else {
    $color = $self->getColor( 0x0301 );
    $scOff = 4;
  }

  $b->moveChar( 0, ' ', $color, $self->{size}{x} );
  if ( $self->{text} ) {
    $b->moveCStr( 1, $self->{text}, $color );
  }
  if ( $showMarkers ) {
    $b->putChar( 0, $specialChars->[$scOff] );
  }
  $self->writeLine( 0, 0, $self->{size}{x}, 1, $b );
  return;
}

my $palette;
sub getPalette {    # $palette ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $palette ||= TPalette->new(
    data => cpLabel, 
    size => length( cpLabel ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );

  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evMouseDown ) {
    $self->$focusLink( $event );
  }
  elsif ( $event->{what} == evKeyDown ) {
    my $c = hotKey( $self->{text} );
    if (
      getAltCode( $c ) == $event->{keyDown}{keyCode}
      || ( $c
        && $self->{owner}{phase} == phPostProcess
        && uc( $event->{keyDown}{charScan}{charCode} ) eq $c )
      )
    {
      $self->$focusLink( $event );
    }
  } #/ elsif ( $event->{what} ==...)
  elsif (
    $event->{what} == evBroadcast && $self->{link}
    && ( $event->{message}{command} == cmReceivedFocus
      || $event->{message}{command} == cmReleasedFocus )
    )
  {
    $self->{light} = ( $self->{link}{state} & sfFocused ) != 0;
    $self->drawView();
  } #/ elsif ( $event->{what} ==...)
  return;
} #/ sub handleEvent

$focusLink = sub {    # void ($event)
  my ( $self, $event ) = @_;
  if ( $self->{link} && ( $self->{link}{options} & ofSelectable ) ) {
    $self->{link}->focus();
  }
  $self->clearEvent( $event );
};

1
