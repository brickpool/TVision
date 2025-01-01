use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN {
  use_ok 'TV::App::DeskInit';
}

isa_ok( TDeskInit->new( cBackground => sub { } ), TDeskInit );

lives_ok {
  my $deskInit = TDeskInit->new(
    cBackground => sub { pass 'called without errors' } 
  );
  $deskInit->createBackground( bless {} );
} 'createBackground works correctly';

done_testing;
