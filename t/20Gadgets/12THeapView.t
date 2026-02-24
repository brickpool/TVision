use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Gadgets::HeapView';
}

{
  package MockHeapView;
  use TV::toolkit;
  extends 'TV::Gadgets::HeapView';
  sub BUILD     { shift->{heapStr} = 'test' }
  sub writeLine { ::pass 'writeLine()'  }
  sub drawView  { ::pass 'drawView()' }
  $INC{"MockHeapView.pm"} = 1;
}

my $view;
subtest 'THeapView->new()' => sub {
  require_ok( 'MockHeapView' );
  $view = MockHeapView->new( bounds => TRect->new() );
  isa_ok( $view, THeapView );
};

subtest 'draw()' => sub {
  can_ok( $view, 'draw' );
  lives_ok { $view->draw() } 'draw() does not die';
};

subtest 'update()' => sub {
  can_ok( $view, 'update' );
  lives_ok {
    $view->{newMem} = 0;
    $view->{oldMem} = 1;    # force branch where drawView() is called
    $view->update();
  } 'update() does not die';
};

subtest 'heapSize()' => sub {
  lives_ok {
    if ( $^O eq 'MSWin32' ) {
      require_ok( 'TV::Gadgets::HeapView::Win32' );

      my $ret = $view->heapSize();
      ok( defined $ret, 'heapSize() returns something on Windows' );
      like( $ret, qr/^-?\d+$/, 'heapSize() returns numeric on Windows' );
    }
    else {
      is( $view->heapSize(), -1, 'heapSize() returns -1 on non-Windows' );
    }
  } 'heapSize() does not die';
}; #/ 'heapSize' => sub

subtest 'fields' => sub {
  ok( $view->{heapStr}, "'heapStr' is defined and not empty" );
  isnt( $view->{heapStr}, 'test', "'heapStr' has a new value" );
};

done_testing();
