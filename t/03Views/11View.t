use 5.014;
use warnings;
use Test::More tests => 51;

BEGIN {
  use_ok 'TurboVision::Const', qw( :bool );
  use_ok 'TurboVision::Objects::Point';
  use_ok 'TurboVision::Objects::Rect';
  use_ok 'TurboVision::Objects::Types', qw( TPoint TRect );
  use_ok 'TurboVision::Drivers::Const', qw( :evXXXX );
  use_ok 'TurboVision::Drivers::Event';
  use_ok 'TurboVision::Drivers::Types', qw( TEvent );
  use_ok 'TurboVision::Views::CommandSet';
  use_ok 'TurboVision::Views::Const', qw( :cmXXXX :dmXXXX :gfXXXX :sfXXXX );
  use_ok 'TurboVision::Views::View';
  use_ok 'TurboVision::Views::Types', qw( TCommandSet TView );
}

note 'test: command_enabled, disable_commands, enable_commands, '
    .'get_commands, set_commands, set_cmd_state';
COMMAND: {
  no strict 'subs';

  my $bounds = TRect->new(0,1,80,24);
  isa_ok($bounds, TRect->class);
  my $view = TView->init($bounds);
  isa_ok($view, TView->class);

  ok(
    $view->command_enabled(CM_QUIT),
    'TView->command_enabled'
  );

  $view->disable_commands([CM_QUIT]),
  ok(
    !$view->command_enabled(CM_QUIT),
    'TView->disable_commands'
  );

  $view->enable_commands([CM_ZOOM]),
  ok(
    $view->command_enabled(CM_ZOOM),
    'TView->enable_commands'
  );
  
  my $cmds = TCommandSet->new();
  isa_ok($cmds, TCommandSet->class);

  $view->get_commands($cmds);
  $view->set_cmd_state([CM_ZOOM], _FALSE),
  ok(
    !$view->command_enabled(CM_ZOOM),
    'TView->set_cmd_state'
  );
  $view->set_commands($cmds);

  my $now = TCommandSet->new();
  isa_ok($now, TCommandSet->class);

  $view->get_commands($now);
  ok(
    $cmds == $now,
    'TView->set_commands'
  );
}

note 'test: size_limits, get_bounds, get_extent, get_clip_rect, mouse_in_view';
INFO_COORD: {
  my $bounds = TRect->init(0,1,80,24);
  isa_ok($bounds, TRect->class);
  my $view = TView->init($bounds);
  my ($min, $max) = ( TPoint->new(), TPoint->new() );
  isa_ok($view, TView->class);
  isa_ok($min, TPoint->class);
  isa_ok($max, TPoint->class);
  $view->size_limits($min, $max);
  ok(
    $min->x == 0 && $min->y == 0
      && 
    $max->y > 80 && $max->y > 25,
    'TView->size_limits'
  );

  $bounds->assign(0,0,0,0);
  $view->get_bounds($bounds);
  ok(
    $bounds->a->x == 0 && $bounds->a->y == 0
      &&
    $bounds->b->x == 80 && $bounds->b->y == 23,
    'TView->get_bounds'
  );
  
  my $extent = TRect->new();
  isa_ok($extent, TRect->class);
  $view->get_extent($extent);
  ok(
    $extent->a->x == 0 && $extent->a->y == 0
      &&
    $extent->b->x == 80 && $extent->b->y == 23,
    'TView->get_extent'
  );

  my $clip = TRect->new();
  isa_ok($clip, TRect->class);
  $view->get_clip_rect($clip);
  ok(
    $extent == $clip,
    'TView->get_clip_rect'
  );

  my $mouse = TPoint->new(x => 1, y => 1);
  isa_ok($mouse, TPoint->class);
  ok(
    $view->mouse_in_view($mouse),
    'TView->mouse_in_view'
  );
}

note 'test: locate, drag_view, calc_bounds, change_bounds, grow_to, move_to, '
    .'set_bounds';
MODIFY_COORD: {
  no strict 'subs';

  my $bounds = TRect->init(0,0,80,25);
  isa_ok($bounds, TRect->class);
  my $view = TView->init($bounds);
  isa_ok($view, TView->class);
  ok(
    !($view->state & SF_EXPOSED),
    '!(TView->state & SF_EXPOSED)'
  );

  $bounds->assign(0,1,80,24);
  $view->set_bounds($bounds);
  ok(
    $view->origin->x == 0 && $view->origin->y == 1
      &&
    $view->size->x == 80 && $view->size->y == 23,
    'TView->set_bounds'
  );

  $bounds->assign(0,0,80,25);
  $view->change_bounds($bounds);
  ok(
    $view->origin->x == 0 && $view->origin->y == 0
      &&
    $view->size->x == 80 && $view->size->y == 25,
    'TView->change_bounds'
  );

  $bounds->assign(0,1,80,24);
  $view->locate($bounds);
  ok(
    $view->origin->x == 0 && $view->origin->y == 1
      &&
    $view->size->x == 80 && $view->size->y == 23,
    'TView->locate'
  );

  $view->move_to(0,0);
  $view->grow_to(80,25);
  ok(
    $view->origin->x == 0 && $view->origin->y == 0
      &&
    $view->size->x == 80 && $view->size->y == 25,
    'TView->move_to && TView->grow_to'
  );

  note 'Set temporary owner';
  $bounds->assign(0,1,80,24);
  my $owner = TView->init($bounds);
  ok(
    exists $$view{owner},
    'exists TView->owner'
  );
  $view->{owner} = $owner;
  ok(
    defined $view->owner,
    'defined TView->owner'
  );

  my $delta = TPoint->new();
  isa_ok($owner, TView->class);
  isa_ok($delta, TPoint->class);
  $view->grow_mode(GF_GROW_ALL);
  ok(
    !!$view->grow_mode,
    'TView->grow_mode'
  );
  $view->calc_bounds($bounds, $delta);
  ok(
    $bounds->a->x == 0 && $bounds->a->y == 0
      &&
    $bounds->b->x == 80 && $bounds->b->y == 23,
    'TView->calc_bounds'
  );

  my $mouse = TPoint->new(x => 1, y => 1);
  isa_ok($mouse, TPoint->class);
  my $event = TEvent->new(what => EV_MOUSE_DOWN, where => $mouse);
  my $mode = DM_DRAG_MOVE | DM_LIMIT_ALL;
  my $min = TPoint->new(x => 0, y => 0);
  my $max = TPoint->new(x => 40, y => 24);
  isa_ok($event, TEvent->class);
  isa_ok($min, TPoint->class);
  isa_ok($max, TPoint->class);
  TODO: {
    todo_skip "'drag_view' doesn't work without TGroup.", 1;
    $view->drag_view($event, $mode, $bounds, $min, $max);
    ok(
      $view->origin->x == 0 && $view->origin->y == 0
        &&
      $view->size->x == 40 && $view->size->y == 23,
      'TView->drag_view'
    );
  }

  note 'Delete temporary owner';
  $view->{owner} = undef;
  ok(
    !defined $view->owner,
    '!defined TView->owner'
  );
}

done_testing();

