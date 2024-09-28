use 5.014;
use warnings;
use Scalar::Util qw( refaddr );

use Test::More tests => 66;
use Test::Exception;

BEGIN {
  note 'use Objects, Drivers, Views';
  use_ok 'TurboVision::Objects::Const', qw( :stXXXX );
  use_ok 'TurboVision::Objects::DosStream';
  use_ok 'TurboVision::Objects::Point';
  use_ok 'TurboVision::Objects::Rect';
  use_ok 'TurboVision::Objects::Types', qw(
    TDosStream
    TPoint
    TRect
  );
  use_ok 'TurboVision::Drivers::Const', qw( :evXXXX );
  use_ok 'TurboVision::Drivers::Event';
  use_ok 'TurboVision::Drivers::ScreenManager', qw( :vars );
  use_ok 'TurboVision::Drivers::Video';
  use_ok 'TurboVision::Drivers::Types', qw( 
    TEvent
    Video
  );
  use_ok 'TurboVision::Views::Const', qw( :sfXXXX );
  use_ok 'TurboVision::Views::View';
  use_ok 'TurboVision::Views::Types', qw( TView );
}

#----------------
note 'Transform';
#----------------
# make_global, make_local
{
  my $bounds = TRect->init(0,0,80,25);
  isa_ok($bounds, TRect->class);

  my $screen = TView->init($bounds);
  isa_ok($screen, TView->class);

  $bounds->assign(1,2,40,24);
  my $view = TView->init($bounds);
  isa_ok($view, TView->class);

  subtest 'set TView->owner' => sub {
    plan tests => 2;
    ok( exists $$view{owner} );
    $view->{owner} = $screen;
    is( refaddr($view->owner), refaddr($screen) );
  };

  my $point = TPoint->new(x => 1, y => 1);
  isa_ok( $point, TPoint->class );

  $view->make_global($point, $point);
  subtest 'TView->make_global' => sub {
    plan tests => 2;
    is( $point->x, 2 );
    is( $point->y, 3 );
  };

  $view->make_local($point, $point);
  subtest 'TView->make_local' => sub {
    plan tests => 2;
    is( $point->x, 1 );
    is( $point->y, 1 );
  };

  subtest 'clear TView->owner' => sub {
    plan tests => 2;
    ok( exists $$view{owner} );
    $view->{owner} = undef;
    is( $view->owner, undef );
  };
}

#---------------
note 'HW-Event';
#---------------
# key_event, mouse_event
{
  no strict 'subs';

  my $bounds = TRect->init(0,0,80,25);
  isa_ok($bounds, TRect->class);

  my $view = TView->init($bounds);
  isa_ok($view, TView->class);

  my $event = TEvent->new();
  isa_ok($event, TEvent->class);

  # EV_KEY_DOWN - exits the internal loop of the key_event method?
  my $mask = EV_KEY_DOWN;
  $event->what($mask);
  $view->key_event($event);
  is(
    $event->what,
    EV_KEY_DOWN,
    'TView->key_event'
  );

  # EV_MOUSE_DOWN - exits the internal loop of the mouse_event method?
  $mask = EV_MOUSE_DOWN;
  subtest 'TView->mouse_event' => sub {
    plan tests => 2;
    $event->what($mask);
    ok( $view->mouse_event($event, $mask) );
    is( $event->what, $mask );
  };
}

#-----------
note 'Draw';
#-----------
# hide, show, draw, exposed, _do_exposed_rec2, _do_exposed_rec1, draw_view, 
# focus, _draw_show, _draw_hide, _draw_under_view, _draw_under_rect
{
  no strict 'subs';

  my $bounds = TRect->init(0,0,80,25);
  isa_ok($bounds, TRect->class);

  my $view = TView->init($bounds);
  isa_ok($view, TView->class);

  is(
    $view->state,
    SF_VISIBLE,
    'TView->state'
  );

  subtest 'TView->hide' => sub {
    plan tests => 2;
    lives_ok { $view->hide };
    ok( !$view->get_state(SF_VISIBLE) );
  };

  subtest 'TView->show' => sub {
    plan tests => 2;
    lives_ok { $view->show };
    ok( $view->get_state(SF_VISIBLE) );
  };

  lives_ok { $view->draw } 'TView->draw';

  subtest 'TView->exposed' => sub {
    plan tests => 2;
    $view->set_state(SF_EXPOSED, 0);
    ok( !$view->exposed );
    $view->set_state(SF_EXPOSED, 1);
    ok( $view->exposed );
  };

  lives_ok { $view->draw_view         } 'TView->draw_view';
  lives_ok { $view->focus             } 'TView->focus';
  lives_ok { $view->_draw_show(undef) } 'TView->_draw_show';
  
  # note "owner is undefined";
  throws_ok { $view->_draw_hide(undef) } qr/undefined/, 
    'TView->_draw_hide & TView->_draw_under_view & TView->_draw_under_rect';
}

#-------------
note 'Cursor';
#-------------
# hide_cursor, block_cursor, normal_cursor, _reset_cursor, set_cursor, 
# _cursor_changed, show_cursor, _draw_cursor
{
  no strict 'subs';

  my $bounds = TRect->init(0,0,80,25);
  isa_ok($bounds, TRect->class);

  my $view = TView->init($bounds);
  isa_ok($view, TView->class);

  $view->show_cursor;
  ok(
    $view->get_state(SF_CURSOR_VIS),
    'TView->show_cursor'
  );
  $view->hide_cursor;
  ok(
    !$view->get_state(SF_CURSOR_VIS),
    'TView->hide_cursor'
  );

  $view->block_cursor;
  ok(
    $view->get_state(SF_CURSOR_INS),
    'TView->block_cursor'
  );
  $view->normal_cursor;
  ok(
    !$view->get_state(SF_CURSOR_INS),
    'TView->normal_cursor'
  );

  $view->set_cursor(1, 1);
  subtest 'TView->set_cursor' => sub {
    plan tests => 2;
    is( $view->cursor->x, 1 );
    is( $view->cursor->y, 1 );
  };
}

#------------
note 'Chain';
#------------
# next_view, prev_view, prev, make_first, put_in_front_of, top_view
{
  my $bounds = TRect->init(0,0,80,25);
  isa_ok($bounds, TRect->class);

  my $a = TView->init($bounds);
  my $b = TView->init($bounds);
  my $c = TView->init($bounds);
  isa_ok($_, TView->class) foreach ($a, $b, $c);

  $a->_next($b);
  $b->_next($c);
  $c->_next($a);

  is (
    refaddr($a->next_view),
    refaddr($b),
    'TView->next_view && TView->next'
  );
  is (
    refaddr($a->prev_view),
    refaddr($c),
    'TView->prev_view && TView->prev'
  );

  can_ok($a, qw(make_first));

  lives_ok(
    sub { $a->put_in_front_of($b) },
    'TView->put_in_front_of'
  );

  is(
    $a->top_view,
    undef,
    'TView->top_view'
  );
}

#------------
note 'Write';
#------------
# write_buf, _do_write_view, _do_write_view_rec2, _do_write_view_rec1, 
# write_char, write_line, write_str
{
  no strict 'subs';

  my $bounds = TRect->init(0,0,80,25);
  isa_ok($bounds, TRect->class);

  my $view = TView->init($bounds);
  isa_ok($view, TView->class);

  subtest 'TProgram->init_screen' => sub { 
    plan tests => 2;
    Video->error_code(0);
    Video->init_video();
    is( 
      Video->error_code, 
      0, 
      'Video->init_video' 
    );
    is( 
      Video->video_buf_size, 
      $screen_width * $screen_height,
      'Video->video_buf_size'
    );
  };

  lives_ok { $view->write_buf(0, 0, 2, 2, $screen_buffer) } 
    'TView->write_buf & TView->_do_write_view_*';

  lives_ok { $view->write_char(0, 0, 'A', 0x70, 2) } 
    'TView->write_char';

  my $buf = [];
  lives_ok { $view->write_line(0, 1, 2, 1, $buf) } 
    'TView->write_line';

  lives_ok { $view->write_str(0, 1, 'ab', 0x07) } 
    'TView->write_str';
  
  Video->done_video();
  is( Video->error_code, 0, 'Video->done_video' );
}

#-------------
note 'Stream';
#-------------
# load, store
{
  no strict 'subs';

  my $bounds = TRect->init(0,0,80,25);
  isa_ok($bounds, TRect->class);

  my $a = TView->init($bounds);
  isa_ok($a, TView->class);

  subtest 'TView->store' => sub {
    plan tests => 2;
    my $stream = TDosStream->init('test.bin', ST_CREATE);
    isa_ok( $stream, TDosStream->class );
    lives_ok { $a->store($stream) } 'store';
  };

  my $b;
  subtest 'TView->load' => sub {
    plan tests => 3;
    my $stream = TDosStream->init('test.bin', ST_OPEN);
    isa_ok( $stream, TDosStream->class );
    lives_ok { $b = TView->load($stream) } 'load';
    isa_ok($b, TView->class);
  };

  is_deeply($a, $b, 'stored == loaded');
}

done_testing();