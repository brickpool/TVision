use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Drivers::Const', qw( evCommand );
  use_ok 'TV::Views::View';
  use_ok 'TV::Util', qw( message );
}

BEGIN {
  package MyTView;
  require TV::Views::View;
  use base 'TV::Views::View';

  my $toggle = 1;
  sub handleEvent {
    my ( $self, $event ) = @_;
    $self->clearEvent( $event ) if $toggle;
    $toggle = 1 - $toggle;
    return;
  }
  $INC{"MyTView.pm"} = 1;
}

use_ok 'MyTView';

# Initial setup
my $bounds = TRect->new();
isa_ok( $bounds, TRect );
my $receiver = MyTView->new( bounds => $bounds );
isa_ok( $receiver, TView );

# Test case 1: Valid Input
my $result = message( $receiver, evCommand, 2, \'info' );
isa_ok( $result, 'MyTView' );

# Test case 2: Non-evNothing Event
$result = message( $receiver, evCommand, 2, \'info' );
is( $result, undef, 'Non-evNothing event test' );

# Test case 3: Undefined Receiver
$result = message( undef, evCommand, 2, \'info' );
is( $result, undef, 'Undefined receiver test' );

done_testing;
