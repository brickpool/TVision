=pod

=head1 DESCRIPTION

These test cases cover the creation of the 'TDisplay' module, the setting and 
retrieval of the fields and the behavior of the subroutines. 

=cut

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

# Mocking 'THardwareInfo' and 'TMouse' for testing purposes
BEGIN {
  package TV::Drivers::HardwareInfo;
  use Exporter 'import';
  our @EXPORT = qw( THardwareInfo );
  sub THardwareInfo() { __PACKAGE__ }
  sub allocateScreenBuffer { return []; }
  sub freeScreenBuffer { }
  sub getCaretSize    { return 10; }
  sub setCaretSize    { }
  sub clearScreen     { }
  sub getScreenRows   { return 25; }
  sub getScreenCols   { return 80; }
  sub getScreenMode   { return 3; }
  sub setScreenMode   { }
  sub getPlatform     { return $^O }
  $INC{"TV/Drivers/HardwareInfo.pm"} = 1;
} #/ BEGIN

BEGIN {
  package TV::Drivers::Mouse;
  use Exporter 'import';
  our @EXPORT = qw( TMouse );
  sub TMouse() { __PACKAGE__ }
  sub present { return 1; }
  sub setRange { }
  $INC{"TV/Drivers/Mouse.pm"} = 1;
}

BEGIN {
  use_ok 'TV::Drivers::HardwareInfo';
  use_ok 'TV::Drivers::Mouse';
  use_ok 'TV::Drivers::Screen';
}

# Test object creation and setCrtData method
my $screen = TScreen();
ok( $screen, 'TScreen exists' );

# Test resume method
can_ok( $screen, 'resume' );
lives_ok { $screen->resume() } 'resume method works correctly';

# Test suspend method
can_ok( $screen, 'suspend' );
lives_ok { $screen->suspend() } 'suspend method works correctly';

# Test fixCrtMode method
can_ok( $screen, 'fixCrtMode' );
is( $screen->fixCrtMode( 3 ), 3, 'fixCrtMode returns correct value' );

# Test setCrtData method
can_ok( $screen, 'setCrtData' );
lives_ok { $screen->setCrtData() } 'setCrtData works correctly';

# Test clearScreen method
can_ok( $screen, 'clearScreen' );
lives_ok { $screen->clearScreen() } 'clearScreen works correctly';

# Test setVideoMode method
can_ok( $screen, 'setVideoMode' );
lives_ok { $screen->setVideoMode( 3 ) } 'setVideoMode works correctly';

done_testing;
