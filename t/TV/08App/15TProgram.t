use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::App::Program';
}

my $bounds = TRect->new( ax => 0, ay => 0, bx => 80, by => 25 );
isa_ok( $bounds, TRect, 'Object is of class TRect' );

# Test object creation
{
  my $program = TProgram->new( bounds => $bounds );
  isa_ok( $program, TProgram, 'Object is of class TProgram' );
  sleep( 3 );
}

done_testing;
