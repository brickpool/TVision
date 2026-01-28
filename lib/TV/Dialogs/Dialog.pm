package TV::Dialogs::Dialog;
# ABSTRACT: Base dialog window class for Turbo Vision dialog boxes

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TDialog
  new_TDialog
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Dialogs::Const qw(
  :cpXXXX
  :dpXXXX
);
use TV::Drivers::Const qw(
  :evXXXX
  kbEsc
  kbEnter
);
use TV::Views::Const qw(
  cmCancel
  cmDefault
  cmNo
  cmOK
  cmYes
  sfModal
  wfMove
  wfClose
  wnNoNumber
);
use TV::Views::Palette;
use TV::Views::Window;
use TV::toolkit;

sub TDialog() { __PACKAGE__ }
sub name() { 'TDialog' }
sub new_TDialog { __PACKAGE__->from(@_) }

extends TWindow;

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  return $class->SUPER::BUILDARGS( @_, number => wnNoNumber );
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert ( blessed $self );
  $self->{growMode} = 0;
  $self->{flags} = wfMove | wfClose;
  $self->{palette} = dpGrayDialog;
  return;
}

sub from {    # $obj ($bounds, $aTitle)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 2 );
  return $class->new( bounds => $_[0], title => $_[1] );
}

my ( $paletteGray, $paletteBlue, $paletteCyan );
sub getPalette {    # $palette ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );

  $paletteGray ||= TPalette->new(
    data => cpGrayDialog,
    size => length( cpGrayDialog ) 
  );
  $paletteBlue ||= TPalette->new( 
    data => cpBlueDialog,
    size => length( cpBlueDialog ) 
  );
  $paletteCyan ||= TPalette->new( 
    data => cpCyanDialog,
    size => length( cpCyanDialog ) 
  );

  SWITCH: for ( $self->{palette} ) {
    dpGrayDialog == $_ and return $paletteGray->clone();
    dpBlueDialog == $_ and return $paletteBlue->clone();
    dpCyanDialog == $_ and return $paletteCyan->clone();
  }
  return $paletteGray->clone();
} #/ sub getPalette

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );

  $self->SUPER::handleEvent( $event );
  SWITCH: for ( $event->{what} ) {
    evKeyDown == $_ and do {
      local $_;
      SWITCH: for ( $event->{keyDown}{keyCode} ) {
        kbEsc == $_ and do {
          $event->{what}             = evCommand;
          $event->{message}{command} = cmCancel;
          $event->{message}{infoPtr} = undef;
          $self->putEvent( $event );
          $self->clearEvent( $event );
          last;
        };
        kbEnter == $_ and do {
          $event->{what}             = evBroadcast;
          $event->{message}{command} = cmDefault;
          $event->{message}{infoPtr} = undef;
          $self->putEvent( $event );
          $self->clearEvent( $event );
          last;
        };
      } #/ SWITCH: for ( $event->{keyDown}...)
      last;
    };

    evCommand == $_ and do {
      local $_;
      SWITCH: for ( $event->{message}{command} ) {
        cmOK == $_      || 
        cmCancel == $_  || 
        cmYes == $_     || 
        cmNo == $_ and do {
          if ( $self->{state} & sfModal ) {
            $self->endModal( $event->{message}{command} );
            $self->clearEvent( $event );
          }
          last;
        };
      } #/ SWITCH: for ( $event->{message}...)
      last;
    };
  } #/ SWITCH: for ( $event->{what} )
  return;
} #/ sub handleEvent

sub valid {    # $bool ($command)
  my ( $self, $command ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $command );
  return $command == cmCancel
    ? !!1
    : $self->SUPER::valid( $command );
}

1

__END__

=pod

=head1 NAME

TDialog - base dialog window class for Turbo Vision dialog boxes

=head1 SYNOPSIS

  use TV::Dialogs;
  use TV::Objects;

  my $bounds = TRect->new(ax => 5, ay => 3, bx => 40, by => 15);
  my $dlg = TDialog->new(bounds => $bounds, title => "Example");

  $dlg->handleEvent($event);

=head1 DESCRIPTION

C<TDialog> implements the fundamental dialog window class used throughout Turbo 
Vision. It handles palette selection, keyboard shortcuts for dialog acceptance 
or cancellation, and manages focus and modal dialog termination.  

The class forms the basis for all higher‑level dialogs and provides common 
event‑handling logic.  

=head1 ATTRIBUTES

=over

=item growMode

Internal window growth behavior flag inherited from C<TWindow> (I<Int>).

=item flags

Internal flag mask enabling movement and closing operations (I<Int>).

=item palette

The currently active dialog palette selection (I<Int> palette constant).

=back

=head1 METHODS

=head2 new

  my $dlg = TDialog->new(%args);

Creates a new C<TDialog> object and initializes its dialog‑specific flags and 
palette.

=over

=item bounds

The bounding rectangle that defines the dialog window position (I<TRect>).

=item title

The dialog window title displayed in the frame (I<Str>).

=back

=head2 new_TDialog

  my $dlg = new_TDialog($bounds, $aTitle);

Factory constructor that creates a C<TDialog> from C<$bounds> and a title.

=head2 getPalette

  my $palette = $self->getPalette();

Returns a clone of the palette object associated with the dialog's color scheme.

=head2 handleEvent

  $self->handleEvent($event);

Processes keyboard and command events, handling ESC, ENTER, and broadcasted 
dialog commands.

=head2 valid

  my $bool = $self->valid($command);

Checks whether the dialog should accept the provided command (C<cmCancel> is 
always valid).

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
