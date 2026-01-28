package TV::Dialogs::Button;
# ABSTRACT: Pushbutton control for Turbo Vision dialogs

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TButton
  new_TButton
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
);

use TV::Dialogs::Const qw(
  :bfXXXX
  :cmXXXX
  cpButton
);
use TV::Dialogs::Util qw( hotKey );
use TV::Drivers::Const qw( :evXXXX );
use TV::Drivers::Event;
use TV::Drivers::Util qw(
  cstrlen
  getAltCode
);
use TV::Views::Const qw(
  cmDefault
  cmCommandSetChanged
  :ofXXXX
  phPostProcess
  :sfXXXX
);
use TV::Views::DrawBuffer;
use TV::Views::Palette;
use TV::Views::View;
use TV::Views::Util qw( message );
use TV::toolkit;

sub TButton() { __PACKAGE__ }
sub name() { 'TButton' }
sub new_TButton { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $shadows = "\xDC\xDB\xDF";
our $markers = "[]";

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
has title     => ( is => 'ro' );
has command   => ( is => 'ro' );
has flags     => ( is => 'rw' );
has amDefault => ( is => 'ro' );

# predeclare private methods
my (
  $drawTitle,
  $pressButton,
  $getActiveRect,
);

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_ );
  my $args2 = check( {
    title     => {
      required    => 1,
      defined     => 1,
      default     => '',
      strict_type => 1,
    },
    command   => { required => 1, defined => 1, allow => qr/^\d+$/ },
    flags     => { required => 1, defined => 1, allow => qr/^\d+$/ },
    amDefault => { default => !!0, no_override => 1 },
  } => { @_ } ) || Carp::confess( last_error );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert ( blessed $self );
  $self->{amDefault} = $self->{flags} & bfDefault;
  $self->{options} |=
    ofSelectable | ofFirstClick | ofPreProcess | ofPostProcess;
  $self->{eventMask} |= evBroadcast;
  $self->{state}     |= sfDisabled
    unless TView->commandEnabled( $self->{command} );
  return;
} #/ sub BUILD

sub from {    # $obj ($bounds, $aTitle, $aCommand, $aFlags)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 4 );
  return $class->new( bounds => $_[0], title => $_[1], command => $_[2], 
    flags => $_[3] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  $self->{title} = undef;
  return;
}

sub draw {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $self->drawState( !!0 );
  return;
}

sub drawState {    # void ($down)
  my ( $self, $down ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( !defined $down or !ref $down );

  my ( $cButton, $cShadow );
  my $ch;
  my $i;
  my $b = TDrawBuffer->new();

  if ( $self->{state} & sfDisabled ) {
    $cButton = $self->getColor( 0x0404 );
  }
  else {
    $cButton = $self->getColor( 0x0501 );
    if ( $self->{state} & sfActive ) {
      if ( $self->{state} & sfSelected ) {
        $cButton = $self->getColor( 0x0703 );
      }
      elsif ( $self->{amDefault} ) {
        $cButton = $self->getColor( 0x0602 );
      }
    }
  } #/ else [ if ( $self->{state} ...)]

  $cShadow = $self->getColor( 8 );

  my $s = $self->{size}{x} - 1;
  my $T = int( $self->{size}{y} / 2 ) - 1;

  for ( my $y = 0 ; $y <= $self->{size}{y} - 2 ; $y++ ) {
    $b->moveChar( 0, ' ', $cButton, $self->{size}{x} );
    $b->putAttribute( 0, $cShadow );
    if ( $down ) {
      $b->putAttribute( 1, $cShadow );
      $ch = ' ';
      $i  = 2;
    }
    else {
      $b->putAttribute( $s, $cShadow );
      if ( $showMarkers ) {
        $ch = ' ';
      }
      else {
        if ( $y == 0 ) {
          $b->putChar( $s, substr( $shadows, 0, 1 ) );
        }
        else {
          $b->putChar( $s, substr( $shadows, 1, 1 ) );
        }
        $ch = substr( $shadows, 2, 1 );
      }
      $i = 1;
    } #/ else [ if ( $down ) ]

    if ( $y == $T && $self->{title} ) {
      $self->$drawTitle( $b, $s, $i, $cButton, $down );
    }

    if ( $showMarkers && !$down ) {
      $b->putChar( 1,      substr( $markers, 0, 1 ) );
      $b->putChar( $s - 1, substr( $markers, 1, 1 ) );
    }

    $self->writeLine( 0, $y, $self->{size}{x}, 1, $b );
  } #/ for ( my $y = 0 ; $y <=...)

  $b->moveChar( 0, ' ', $cShadow, 2 );
  $b->moveChar( 2, $ch, $cShadow, $s - 1 );

  $self->writeLine( 0, $self->{size}{y} - 1, $self->{size}{x}, 1, $b );
  return;
} #/ sub drawState

my $palette;
sub getPalette {    # $palette ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $palette ||= TPalette->new(
    data => cpButton, 
    size => length( cpButton ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );

  my $mouse; 
  my $clickRect;

  $clickRect = $self->getExtent();
  $clickRect->{a}{x}++;
  $clickRect->{b}{x}--;
  $clickRect->{b}{y}--;

  if ( $event->{what} == evMouseDown ) {
    $mouse = $self->makeLocal( $event->{mouse}{where} );
    if ( !$clickRect->contains( $mouse ) ) {
      $self->clearEvent( $event );
    }
  }
  if ( $self->{flags} & bfGrabFocus ) {
    $self->SUPER::handleEvent( $event );
  }

  my $c = hotKey( $self->{title} );
  SWITCH: for ( $event->{what} ) {
    evMouseDown == $_ and do {
     if ( ( $self->{state} & sfDisabled ) == 0 ) {
        $clickRect->{b}{x}++;
        my $down = !!0;
        do {
          $mouse = $self->makeLocal( $event->{mouse}{where} );
          if ( !$down != !$clickRect->contains( $mouse ) ) {
            $down = !$down;
            $self->drawState( $down );
          }
        } while ( $self->mouseEvent( $event, evMouseMove ) );
        if ( $down ) {
          $self->press();
          $self->drawState( !!0 );
        }
      } #/ if ( ( $self->{state} ...))
      $self->clearEvent( $event );
      last;
    };

    evKeyDown == $_ and do {
      if (
        $event->{keyDown}{keyCode} == getAltCode( $c )
        || ( $self->{owner}{phase} == phPostProcess
          && $c
          && uc( $event->{keyDown}{charScan}{charCode} ) eq $c )
        || ( ( $self->{state} & sfFocused )
          && $event->{keyDown}{charScan}{charCode} eq ' ' )
        )
      {
        $self->press();
        $self->clearEvent( $event );
      } #/ if ( $event->{keyDown}...)
      last;
    };

    evBroadcast == $_ and do {
      local $_;
      SWITCH: for ( $event->{message}{command} ) {
        cmDefault == $_ and do {
          if ( $self->{amDefault} && !( $self->{state} & sfDisabled ) ) {
            $self->press();
            $self->clearEvent( $event );
          }
          last;
        };

        cmGrabDefault == $_ || 
        cmReleaseDefault == $_ and do {
          if ( $self->{flags} & bfDefault ) {
            $self->{amDefault} = $event->{message}{command} == cmReleaseDefault;
            $self->drawView();
          }
          last;
        };

        cmCommandSetChanged == $_ and do {
          $self->setState(
            sfDisabled,
            !TView->commandEnabled( $self->{command} ) ? !!1 : !!0
          );
          $self->drawView();
          last;
        };
      } #/ SWITCH: for ( $event->{message}...)
      last;
    };

  } #/ SWITCH: for ( $event->{what} )
  return;
} #/ sub handleEvent

sub makeDefault {    # void ($enable)
  my ( $self, $enable ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( !defined $enable or !ref $enable );

  if ( ( $self->{flags} & bfDefault ) == 0 ) {
    message(
      $self->{owner},
      evBroadcast,
      $enable ? cmGrabDefault : cmReleaseDefault,
      $self
    );
    $self->{amDefault} = $enable;
    $self->drawView();
  } #/ if ( ( $self->{flags} ...))
  return;
} #/ sub makeDefault

sub press {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );

  message( $self->{owner}, evBroadcast, cmRecordHistory, undef );

  if ( $self->{flags} & bfBroadcast ) {
    message( $self->{owner}, evBroadcast, $self->{command}, $self );
  }
  else {
    my $e = TEvent->new();
    $e->{what} = evCommand;
    $e->{message}{command} = $self->{command};
    $e->{message}{infoPtr} = $self;
    $self->putEvent( $e );
  }
  return;
} #/ sub press

sub setState { # void ($aState, $enable)
  my ( $self, $aState, $enable ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( looks_like_number $aState );
  assert ( !defined $enable or !ref $enable );

  $self->SUPER::setState( $aState, $enable );
  if ( $aState & ( sfSelected | sfActive ) ) {
    if ( !$enable ) {
      # BUG FIX - EFW - Thu 10/19/95
      $self->{state} &= ~sfFocused;
      $self->makeDefault( !!0 );
    }
    $self->drawView();
  }

  if ( $aState & sfFocused ) {
    $self->makeDefault( $enable );
  }
  return;
} #/ sub setState

$drawTitle = sub {    # void ($b, $s, $i, $cButton, $down)
  my ( $self, $b, $s, $i, $cButton, $down ) = @_;

  my ( $l, $scOff );
  if ( $self->{flags} & bfLeftJust ) {
    $l = 1;
  }
  else {
    my $len = cstrlen( $self->{title} );
    $l = int( ( $s - $len - 1 ) / 2 );
    $l = 1 if $l < 1;
  }

  $b->moveCStr( $i + $l, $self->{title}, $cButton );

  if ( $showMarkers && !$down ) {
    if ( $self->{state} & sfSelected ) {
      $scOff = 0;
    }
    elsif ( $self->{amDefault} ) {
      $scOff = 2;
    }
    else {
      $scOff = 4;
    }
    $b->putChar( 0,  $specialChars->[$scOff] );
    $b->putChar( $s, $specialChars->[$scOff + 1] );
  } #/ if ( $self->{showMarkers...})
  return;
}; #/ sub drawTitle

$pressButton = sub {    # void ($event)
  ...;
};

$getActiveRect = sub {    # $rect ()
  ...;
};

1

__END__

=pod

=head1 NAME

TV::Dialogs::Button - pushbutton control for Turbo Vision dialogs

=head1 SYNOPSIS

  use TV::Dialogs;

  my $btn = TButton->new(bounds => $bounds, title => "~O~K", command => cmOK, 
    flags => bfNormal);

=head1 DESCRIPTION

C<TButton> implements an interactive pushbutton control with full Turbo Vision 
semantics. It supports highlighting, shadow rendering, pressing behavior, 
default-button logic, and command dispatch.  

Mouse and keyboard events are handled according to Turbo Vision's original 
model. 

=head1 ATTRIBUTES

=over

=item title

The caption displayed on the button, usually containing a hotkey marker 
(I<Str>).

=item command

The command identifier triggered when the button is pressed (I<Int>).

=item flags

Bit‑mask of behavioral settings such as default, broadcast or selectable 
(I<Int>).

=item amDefault

Boolean flag indicating whether the button is currently treated as the dialog's 
default button (I<Bool>).

=back

=head1 METHODS

=head2 new

  my $btn = TButton->new(%args);

Creates a new button with bounds, a title string, a command identifier and 
behavioral flags.

=over

=item bounds

The rectangular region that defines the button's position (I<TRect>).

=item title

The caption displayed on the button, usually with a hotkey marker (I<Str>).

=item command

The command ID broadcast when the button is pressed (I<Int>).

=item flags

Behavioral flags controlling default state, focus handling and selection 
(I<bfXXXX>).

=back

=head2 new_TButton

 my $obj = new_TButton($bounds, $aTitle, $aCommand, $aFlags);

Factory constructor for building a Turbo‑Vision‑style button control.

=head2 draw

 $self->draw();

Renders the button according to its current state.

=head2 drawState

 $self->drawState($down);

Draws the button in pressed or unpressed visual form.

=head2 getPalette

 my $palette = $self->getPalette();

Returns the drawing palette for a button control.

=head2 handleEvent

 $self->handleEvent($event);

Processes mouse clicks, key presses and broadcast events for the button.

=head2 makeDefault

 $self->makeDefault($enable);

Marks or unmarks the button as the dialog's default action button.

=head2 press

 $self->press();

Sends the button's command to the dialog owner.

=head2 setState

 $self->setState($aState, $enable);

Updates the control's internal state and refreshes its appearance.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). 

=cut
