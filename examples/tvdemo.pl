package TVDemo;

use TV::Objects;
use TV::Menus;
use TV::Drivers;
use TV::App;
use TV::Views;
use TV::Dialogs;
use TV::Gadgets;

use TV::toolkit;

sub ::new_TVDemo { __PACKAGE__->new( argc => shift, argv => shift ) }

extends TApplication;

# Constants for TVDemo events
use constant {
  cmAboutCmd     => 100,
  cmEventViewCmd => 112,
};

# Constants for TVDemo help
use constant {
  hcSystem => 7,
  hcSAbout => 8,
};

sub BUILDARGS {
  return {
    %{ shift->SUPER::BUILDARGS() },
    argc   => $_{argc} || 0,
    argv   => $_{argv} || [],
    bounds => new_TRect( 0, 0, 80, 25 ),
  };
}

#
# DemoApp::getEvent()
#  Event loop to check for context help request
#

my $helpInUse = 0;
sub getEvent {    # void ($event)
  my $self = shift;
  alias: for my $event ( shift ) {

  $self->SUPER::getEvent( $event );
  $self->printEvent( $event );

  q[*
  SWITCH: for ( $event->{what} ) {
    evCommand == $_ and do {
      if ( $event->{message}{command} == cmHelp && !$helpInUse ) {
        $helpInUse = 1;

        # Try to open help file
        my $helpStrm;
        if ( open $helpStrm, '<:raw', HELP_FILENAME ) {
          my $hFile = THelpFile->new( $helpStrm );
          my $w     = THelpWindow->new( $hFile, $self->getHelpCtx() );

          if ( $self->validView( $w ) ) {
            $self->execView( $w );
            $self->destroy( $w );
          }

          $self->clearEvent( $event );
        } #/ if ( open $helpStrm, '<:raw'...)
        else {
          $self->messageBox( "Could not open help file", mfError | mfOKButton );
        }

        $helpInUse = 0;
      } #/ if ( $event->{message}...)
      elsif ( $event->{message}{command} == cmVideoMode ) {
        my $newMode = TScreen::screenMode() ^ TDisplay::smFont8x8();
        $self->setScreenMode( $newMode );
      }
      last;
    };
    evMouseDown == $_ and do {
      if ( $event->{mouse}{buttons} == mbRightButton ) {
        $event->{what} = evNothing;
      }
      last;
    }
  } #/ SWITCH: for ( $event->{what} )
  q*] if 0;
  return;
  } #/ alias: for my $event
} #/ sub getEvent

#
# Create statusline.
#

sub initStatusLine {
  my ( $class, $r ) = @_;
  $r->{a}{y} = $r->{b}{y} - 1;

  return new_TStatusLine( $r,
    new_TStatusDef( 0, 50 ) +
      new_TStatusItem( "~F1~ Help", kbF1,  cmHelp ) +
      new_TStatusItem( "~Alt-X~ Exit", kbAltX, cmQuit ) +
      new_TStatusItem( '', kbShiftDel, cmCut ) +
      new_TStatusItem( '', kbCtrlIns, cmCopy ) +
      new_TStatusItem( '', kbShiftIns, cmPaste ) +
      new_TStatusItem( '', kbAltF3, cmClose ) +
      new_TStatusItem( '', kbF10, cmMenu ) +
      new_TStatusItem( '', kbF5, cmZoom ) +
      new_TStatusItem( '', kbCtrlF5, cmResize ) +
    new_TStatusDef( 0, 50 ) +
      new_TStatusItem( "Howdy", kbF1,  cmHelp )
  );
}

#
# Menubar initialization.
#

sub initMenuBar {
  my ( $class, $r ) = @_;
  
  my $sub1 = 
    new_TSubMenu( "~\360~", 0, hcSystem ) +
      new_TMenuItem( "~A~bout...", cmAboutCmd, kbNoKey, hcSAbout ) +
      newLine() +
      new_TMenuItem( "~E~vent Viewer", cmEventViewCmd, kbAlt0, hcNoContext, 
        "Alt-0" );

  $r->{b}{y} = $r->{a}{y} + 1;
  return new_TMenuBar( $r, $sub1 );
}

#
# DemoApp::handleEvent()
#  Event loop to distribute the work.
#

sub handleEvent {
  my ( $self, $event ) = @_;
  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {

      cmAboutCmd == $_ and do {        #  About Dialog Box
        $self->aboutDlgBox();
        last;
      };

      cmEventViewCmd == $_ and do {    #  Open Event Viewer
        $self->eventViewer();
        last;
      };

      DEFAULT: {                       #  Unknown command
        return;
      }
    } #/ SWITCH: for ( $event->{message}...)
    $self->clearEvent( $event );
  } #/ if ( $event->{what} ==...)
  return;
} #/ sub handleEvent

#
# About Box function()
#

sub aboutDlgBox {
  my ( $self ) = @_;
  my $aboutBox = new_TDialog( new_TRect( 0, 0, 39, 13 ), "About" );

  $aboutBox->insert(
    new_TStaticText(
      new_TRect( 9, 2, 30, 9 ),
        "\003Turbo Vision Demo\n\n" .        # These strings will be
        "\003C++ Perl Port Version\n\n" .    # concatenated by the compiler.
        "\003Copyright (c) 1994\n\n" .       # The \003 centers the line.
        "\003Borland International"
    )
  );

  $aboutBox->insert(
    new_TButton( new_TRect( 14, 10, 26, 12 ), " OK", cmOK, bfDefault ) );

  $aboutBox->{options} |= ofCentered;

  $self->executeDialog( $aboutBox );
  return;
} #/ sub aboutDlgBox

#
# Event Viewer function
#

sub eventViewer {
  my ( $self ) = @_;
  my $viewer = message( $deskTop, evBroadcast, cmFndEventView, 0 );
  if ( $viewer ) {
    $viewer->toggle();
  }
  else {
    $deskTop->insert(
      new_TEventViewer( $deskTop->getExtent(), 0x0F00 ) );
  }
  return;
}

sub printEvent {
  my ( $self, $event ) = @_;
  my $viewer = message( $deskTop, evBroadcast, cmFndEventView, 0 );
  if ( $viewer ) {
    $viewer->print( $event );
  }
  return;
}

package main; 

#
# main: create an application object.  Constructor takes care of all
#   initialization.  Calling run() from TProgram makes it tick and
#   the destructor will destroy the world.
#
#   File names can be specified on the command line for automatic
#   opening.
#

sub main {
  my ( $argc, $argv ) = @_;
  my $demoProgram = new_TVDemo( $argc, $argv );

  $demoProgram->run();

  $demoProgram = undef;
  return 0;
}

exit main( scalar @ARGV, \@ARGV );
