=pod

=head1 DESCRIPTION

These test cases cover the methods I<setRange>, I<getEvent>, I<present>, 
I<inhibit>, I<resume>, I<suspend>, I<show>, and I<hide> of the I<THWMouse> 
class. 

=cut

use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;

BEGIN {
  use_ok 'TV::Drivers::HardwareInfo';
  use_ok 'TV::Drivers::HWMouse';
  use_ok 'TV::Drivers::Mouse';
}

# Test TMouse
my $mouse = TMouse();
ok( $mouse, 'TMouse exists' );
can_ok( $mouse, 'resume' );
can_ok( $mouse, 'suspend' );
can_ok( $mouse, 'show' );
can_ok( $mouse, 'hide' );
can_ok( $mouse, 'setRange' );
can_ok( $mouse, 'getEvent' );
can_ok( $mouse, 'present' );

# Test methods
lives_ok { $mouse->resume() } 'resume() does not die';
lives_ok { $mouse->suspend() } 'suspend() does not die';
lives_ok { $mouse->show() } 'show() does not die';
lives_ok { $mouse->hide() } 'hide() does not die';
lives_ok { $mouse->getEvent( {} ) } 'getEvent() does not die';
ok( !$mouse->present(), 'present() returns false' );

# Test setRange method
lives_ok { $mouse->setRange( 100, 200 ) } 'setRange(100, 200) does not die';

# Test THWMouse
$mouse = THWMouse();
ok( $mouse, 'THWMouse exists' );
can_ok( $mouse, 'inhibit' );

# Test inhibit method
lives_ok { $mouse->inhibit() } 'inhibit() does not die';

done_testing;
