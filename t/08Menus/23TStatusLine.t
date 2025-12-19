#!perl

=pod

=head1 DESCRIPTION

These test cases check the creation and destruction of C<TStatusLine> objects, 
as well as the C<draw>, C<getPalette>, and C<handleEvent> methods. 

=cut

use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Drivers::Event';
  use_ok 'TV::Menus::StatusDef';
  use_ok 'TV::Menus::StatusLine';
}

# Test case for the constructor
subtest 'constructor' => sub {
  my $bounds      = new_TRect( 0, 0, 10, 10 );
  my $defs        = new_TStatusDef( 0, 0 );
  my $status_line = new_TStatusLine( $bounds, $defs );
  isa_ok( $status_line, TStatusLine, 'TStatusLine object created' );
};

# Test case for the destructor
subtest 'destructor' => sub {
  my $bounds      = new_TRect( 0, 0, 10, 10 );
  my $defs        = new_TStatusDef( 0, 0 );
  my $status_line = new_TStatusLine( $bounds, $defs );
  $status_line->DEMOLISH(0);
  ok( !$status_line->{defs}, 'TStatusLine object destroyed' );
};

# Test case for the draw method
subtest 'draw method' => sub {
  my $bounds      = new_TRect( 0, 0, 10, 10 );
  my $defs        = new_TStatusDef( 0, 0 );
  my $status_line = new_TStatusLine( $bounds, $defs );
  can_ok( $status_line, 'draw' );
  lives_ok { $status_line->draw() } 
    'TStatusLine->draw() works correctly';
};

# Test case for the getPalette method
subtest 'getPalette method' => sub {
  my $bounds      = new_TRect( 0, 0, 10, 10 );
  my $defs        = new_TStatusDef(0, 0 );
  my $status_line = new_TStatusLine( $bounds, $defs );
  can_ok( $status_line, 'getPalette' );
  lives_ok { $status_line->getPalette() } 
    'TStatusLine->getPalette() works correctly';
};

# Test case for the handleEvent method
subtest 'handleEvent method' => sub {
  my $bounds      = new_TRect( 0, 0, 10, 10 );
  my $event       = TEvent->new();
  my $defs        = new_TStatusDef( 0, 0 );
  my $status_line = new_TStatusLine( $bounds, $defs );
  can_ok( $status_line, 'handleEvent' );
  lives_ok { $status_line->handleEvent( $event ) } 
    'TStatusLine->handleEvent() works correctly';
};

done_testing;
