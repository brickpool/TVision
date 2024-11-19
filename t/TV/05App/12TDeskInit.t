use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::App::DeskInit';
}

isa_ok( TDeskInit->new( sub { } ), TDeskInit );

my $deskInit = TDeskInit->new( sub { pass 'called without errors' } );
$deskInit->createBackground( bless {} );

done_testing;
