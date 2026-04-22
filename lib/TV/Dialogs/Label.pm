package TV::Dialogs::Label;
# ABSTRACT: Provides a descriptive label linked to another dialog control.

use 5.010;
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

use TV::toolkit;
use TV::toolkit::Types qw(
  Maybe
  is_Object
  :types
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

# protected attributes
has link  => ( is => 'ro', default => sub { die 'required' } );
has light => ( is => 'ro', default => false );

# predeclare private methods
my (
  $focusLink,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds => Object,
      text   => Str,           { alias => 'aText' },
      link   => Maybe[Object], { alias => 'aLink' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{options} |= ofPreProcess | ofPostProcess;
  $self->{eventMask} |= evBroadcast;
  return;
}

sub from {    # $obj ($bounds, $aText, $aLink|undef)
  state $sig = signature(
    method => 1,
    pos    => [Object, Str, Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], text => $args[1], link => $args[2] );
}

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{link} = undef;
  $self->SUPER::shutDown();
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
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

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new( data => cpLabel, size => length( cpLabel ) );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );

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
    ) {
      $self->$focusLink( $event );
    }
  } #/ elsif ( $event->{what} ==...)
  elsif (
    $event->{what} == evBroadcast && $self->{link}
    && ( $event->{message}{command} == cmReceivedFocus
      || $event->{message}{command} == cmReleasedFocus )
  ) {
    $self->{light} = ( $self->{link}{state} & sfFocused ) != 0;
    $self->drawView();
  } #/ elsif ( $event->{what} ==...)
  return;
} #/ sub handleEvent

$focusLink = sub {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $event );
  if ( $self->{link} && ( $self->{link}{options} & ofSelectable ) ) {
    $self->{link}->focus();
  }
  $self->clearEvent( $event );
  return;
};

1

__END__

=pod

=head1 NAME

TLabel - provides a descriptive label linked to another dialog control

=head1 SYNOPSIS

  use TV::Dialogs;

  my $label = TLabel->new(bounds => $bounds, text => "~N~ame:", 
    link => $inputLine);

=head1 DESCRIPTION

C<TLabel> represents a static text label associated with another control.  
It highlights based on focus changes and forwards activation events to its 
linked control. The class supports hotkey activation through marked characters. 

=head1 ATTRIBUTES

=over

=item link

The control associated with the label and activated through its hotkey 
(I<TView>).

=item light

Indicates whether the label is displayed in its highlighted variant (I<Bool>).

=back

=head1 METHODS

=head2 new

  my $label = TLabel->new(%args);

Creates a new C<TLabel> with bounds, label text and an optional link target.

=over

=item bounds

The rectangular area where the label is placed (I<TRect>).

=item text

The displayed label string, optionally containing a hotkey marker (I<Str>).

=item link

A control that receives focus when the label is activated (I<TView> or undef).

=back

=head2 new_TLabel

  my $label = new_TLabel($bounds, $aText, $aLink | undef);

Factory constructor that instantiates a label from C<$bounds>, C<$aText> and a 
linked control.

=head2 draw

 $self->draw();

Draws the label and renders its hotkey and optional marker symbols.

=head2 getPalette

 my $palette = $self->getPalette();

Returns the palette used for rendering the label.

=head2 handleEvent

 $self->handleEvent($event);

Processes mouse and keyboard events to activate or highlight the linked control.

=head2 shutDown

 $self->shutDown();

Releases the internal link reference during destruction.

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
