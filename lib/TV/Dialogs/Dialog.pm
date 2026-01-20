package TV::Dialogs::Dialog;
# ABSTRACT: 

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

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Drivers::Const qw(
  evKeyDown
  evCommand
  evBroadcast
  kbEsc
  kbEnter
);
use TV::Dialogs::Const qw(
  :cpXXXX
  :dpXXXX
);
use TV::Views::Const qw(
  cmDefault
  cmOK
  cmCancel
  cmYes
  cmNo
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
  assert( @_ == 2 );
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
  assert( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $command );

  return $command == cmCancel
    ? !!1
    : $self->SUPER::valid( $command );
}

1
