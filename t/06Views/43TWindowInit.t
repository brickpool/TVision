use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN {
  use_ok 'TV::Views::WindowInit';
}

isa_ok( TWindowInit->new( cFrame => sub { } ), TWindowInit );

lives_ok {
  my $windowInit = TWindowInit->new(
    cFrame => sub { pass 'called without errors' } 
  );
  $windowInit->createFrame( bless {} );
} 'createFrame works correctly';

done_testing;
