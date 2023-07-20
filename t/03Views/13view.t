use 5.014;
use warnings;
use Test::More tests => 42;
use Test::Exception;
use Scalar::Util qw( refaddr );

BEGIN {
  note 'use Objects, Drivers, Views';
  use_ok 'TurboVision::Const', qw( :bool );
  use_ok 'TurboVision::Objects::Point';
  use_ok 'TurboVision::Objects::Rect';
  use_ok 'TurboVision::Objects::Types', qw( TPoint TRect );
  use_ok 'TurboVision::Drivers::Const', qw( :evXXXX );
  use_ok 'TurboVision::Drivers::Event';
  use_ok 'TurboVision::Drivers::Types', qw( TEvent );
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

  # EV_KEY_DOWN exits the internal loop of the key_event method
  my $mask = EV_KEY_DOWN;
  $event->what($mask);
  $view->key_event($event);
  is(
    $event->what,
    EV_KEY_DOWN,
    'TView->key_event'
  );

  # EV_MOUSE_DOWN exits the internal loop of the mouse_event method
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
# hide, show, draw, draw_view, exposed, focus, draw_hide, draw_show, 
# _draw_under_rect, _draw_under_view
{
  ok 1
}

#-------------
note 'Cursor';
#-------------
# hide_cursor, block_cursor, normal_cursor, _reset_cursor, set_cursor, 
# show_cursor, _draw_cursor
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
# write_buf, write_char, write_line, write_str
{
  ok 1
}

#-------------
note 'Stream';
#-------------
# load, store
{
  ok 1
}

done_testing();