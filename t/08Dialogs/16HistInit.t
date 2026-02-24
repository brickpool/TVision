use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Views::Window';
  use_ok 'TV::Dialogs::HistInit';
}

my $histInit = THistInit->new(
  cListViewer => sub { pass 'cListViewer called without errors' },
);
isa_ok( $histInit, THistInit );

my $win = TWindow->new( bounds => TRect->new(), title => '', number => 0 );
isa_ok( $win, TWindow );

lives_ok {
  $histInit->createListViewer( TRect->new(), $win, 0 );
} 'createListViewer works correctly';

done_testing;
