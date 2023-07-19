use 5.014;
use warnings;
use Test::More tests => 50;
use Test::Exception;
use Scalar::Util qw( refaddr );

BEGIN {
  note "use Objects, Drivers, Views";
  use_ok 'TurboVision::Const', qw( :bool );
  use_ok 'TurboVision::Objects::Point';
  use_ok 'TurboVision::Objects::Rect';
  use_ok 'TurboVision::Objects::Types', qw( TPoint TRect );
  use_ok 'TurboVision::Drivers::Const', qw( :evXXXX );
  use_ok 'TurboVision::Drivers::Event';
  use_ok 'TurboVision::Drivers::Types', qw( TEvent );
  use_ok 'TurboVision::Views::Const', qw( :cmXXXX :dmXXXX :hcXXXX :ofXXXX :sfXXXX );
  use_ok 'TurboVision::Views::View';
  use_ok 'TurboVision::Views::Types', qw( TView );
}

note 'test: size, options, event_mask, state, origin, cursor, grow_mode, '
    .'drag_mode, help_ctx, owner';
ATTR: {
  ok 1;
}

note 'test: make_global, make_local';
TRANS_COORD: {
  ok 1;
}

note 'test: get_help_ctx, valid, end_modal, execute';
HELPER: {
  no strict 'subs';
  
  my $bounds = TRect->init(0,0,80,25);
  isa_ok($bounds, TRect->class);

  my $view = TView->init($bounds);
  isa_ok($view, TView->class);

  is(
    $view->get_help_ctx,
    HC_NO_CONTEXT,
    'TView->get_help_ctx'
  );

  ok(
    $view->valid(CM_VALID),
    'TView->valid'
  );

  ok(
    $view->valid(CM_VALID),
    'TView->valid'
  );

  lives_ok(
    sub { $view->end_modal(CM_CANCEL) }, 
    'TView->end_modal'
  );

  is(
    $view->execute,
    CM_CANCEL,
    'TView->execute'
  );
}

note 'test: data_size, get_data, set_data';
DATA: {
  my $bounds = TRect->init(0,0,80,25);
  isa_ok($bounds, TRect->class);

  my $view = TView->init($bounds);
  isa_ok($view, TView->class);

  is(
    $view->data_size,
    0,
    'TView->data_size'
  );

  my $rec = "\0" x $view->data_size;
  lives_ok(
    sub { $view->set_data($rec) }, 
    'TView->set_data'
  );

  lives_ok( 
    sub { $view->get_data($rec) },
     'TView->get_data'
  );
}

note 'test: get_state, select, set_state';
STATE: {
  no strict 'subs';

  my $bounds = TRect->init(0,0,80,25);
  isa_ok($bounds, TRect->class);

  my $view = TView->init($bounds);
  isa_ok($view, TView->class);

  is(
    $view->options,
    0,
    'TView->options'
  );
  lives_ok(
    sub { $view->select },
    'TView->select'
  );

  is(
    $view->state,
    SF_VISIBLE,
    'TView->state'
  );

  ok(
    $view->get_state(SF_VISIBLE),
    'TView->get_state'
  );

  $view->set_state(SF_VISIBLE, _FALSE);
  ok(
    !$view->get_state(SF_VISIBLE),
    'TView->set_state'
  );
}

note 'test: clear_event, event_avail, get_event, handle_event, put_event';
EVENT: {
  no strict 'subs';

  my $bounds = TRect->init(0,0,80,25);
  isa_ok($bounds, TRect->class);

  my $view = TView->init($bounds);
  isa_ok($view, TView->class);

  my $event = TEvent->new(
    what => EV_COMMAND, 
    command => CM_CANCEL,
  );
  isa_ok($event, TEvent->class);

  $view->put_event($event);
  is(
    $event->what,
    EV_COMMAND,
    'TView->put_event'
  );

  $view->get_event($event);
  is(
    $event->what,
    EV_COMMAND,
    'TView->get_event'
  );

  $view->clear_event($event);
  is(
    $event->what,
    EV_NOTHING,
    'TView->clear_event && TEvent->what'
  );
  is(
    refaddr($event->info_ptr),
    refaddr($view),
    'TView->clear_event && TEvent->info_ptr'
  );

  ok(
    !$view->event_avail,
    '!TView->event_avail'
  );

  $view->options(OF_SELECTABLE);
  $event->what(EV_MOUSE_DOWN);
  $view->handle_event($event);
  is(
    $event->what,
    EV_NOTHING,
    'TView->handle_event'
  );
}

note 'test: key_event, mouse_event';
HW_EVENT: {
  ok 1;
}

note 'test: get_color, get_palette';
COLOR: {
  my $bounds = TRect->init(0,0,80,25);
  isa_ok($bounds, TRect->class);

  my $view = TView->init($bounds);
  isa_ok($view, TView->class);

  is(
    $view->get_palette,
    undef,
    'TView->get_palette'
  );

  is(
    $view->get_color(0),
    TView->_ERROR_ATTR, # 0xcf
    'TView->get_color'
  );
}

note 'test: hide, show, draw, draw_view, exposed, focus, draw_hide, draw_show, '
    .'draw_under_rect, draw_under_view';
DRAW: {
  ok 1;
}

note 'test: hide_cursor, awaken, block_cursor, normal_cursor, set_cursor, '
    .'show_cursor';
CURSOR: {
  ok 1;
}

note 'test: next_view, prev_view, prev, next, make_first, put_in_front_of';
OWNER: {
  ok 1;
}

note 'test: write_buf, write_char, write_line, write_str';
WRITE: {
  ok 1;
}

note 'test: load, store';
STREAM: {
  ok 1;
}

done_testing();