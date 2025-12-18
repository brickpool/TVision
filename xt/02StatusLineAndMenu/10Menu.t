=pod

=head1 NAME

Add a menu.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/02_-_Statuszeile_und_Menu/10_-_Menu>

=cut

use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

use constant ManualTestsEnabled => exists($ENV{MANUAL_TESTS})
                                && !$ENV{AUTOMATED_TESTING}
                                && !$ENV{NONINTERACTIVE_TESTING};

# The same modules are used for the menu as for the status line.
BEGIN {
  use_ok 'TV::App';
  use_ok 'TV::Views';
  use_ok 'TV::Drivers';
  use_ok 'TV::Objects';
  use_ok 'TV::Menus';
  use_ok 'TV::toolkit';
}

BEGIN {
  package TMyApp;

  use TV::App;      # TApplication
  use TV::Views;    # Event (cmQuit)
  use TV::Drivers;  # Hotkey
  use TV::Objects;  # Window section (TRect)
  use TV::Menus;    # Status line and menu
  use TV::toolkit;

  extends TApplication;

  # We want to use a console resolution like MS DOS.
  sub BUILDARGS {
    my $args = shift->SUPER::BUILDARGS( @_ ) || return;
    $args->{bounds} = new_TRect( 0, 0, 80, 25 );
    return $args;
  }

  # For a menu, you must overwrite initMenuBar.
  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return
      new_TMenuBar( $r, 
        new_TSubMenu( '~F~ile', hcNoContext ) + 
          new_TMenuItem( 'E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X' )
      );
  }

  $INC{"TMyApp.pm"} = 1;
}

use_ok 'TMyApp';
SKIP: {
  skip 'Manual test not enabled', 2 unless ManualTestsEnabled();
  my $myApp = TMyApp->new();
  isa_ok( $myApp, TApplication );
  lives_ok { $myApp->run() } 'TMyApp object executed successfully';
}

done_testing;
