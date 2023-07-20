use 5.014;
use warnings;
use Test::More tests => 64;

BEGIN {
  note 'use Objects, Drivers, Views';
  use_ok 'TurboVision::Const', qw( :bool );
  use_ok 'TurboVision::Objects::Point';
  use_ok 'TurboVision::Objects::Rect';
  use_ok 'TurboVision::Objects::Types', qw( TPoint TRect );
  use_ok 'TurboVision::Drivers::Const', qw( :evXXXX );
  use_ok 'TurboVision::Drivers::Event';
  use_ok 'TurboVision::Drivers::Types', qw( TEvent );
  use_ok 'TurboVision::Views::CommandSet';
  use_ok 'TurboVision::Views::Const', qw( :cmXXXX :dmXXXX :gfXXXX :hcXXXX :sfXXXX );
  use_ok 'TurboVision::Views::View';
  use_ok 'TurboVision::Views::Types', qw( TCommandSet TView );
}

#-----------------
note 'Attributes';
#-----------------
# next, size, options, event_mask, state, origin, cursor, grow_mode, drag_mode, 
# help_ctx, owner
{
  can_ok(TView->class, qw( 
    next
    size 
    options
    event_mask
    state
    origin
    cursor
    grow_mode
    drag_mode
    help_ctx
    owner
  ));
}

#-----------------
note 'Constructor';
#-----------------
# init
{
  no strict 'subs';

  my $bounds = TRect->init(0,1,80,24);
  isa_ok($bounds, TRect->class);

  my $view = TView->init($bounds);
  isa_ok($view, TView->class);

  is(
    $view->owner,
    undef,
    'TView->owner'
  );
  is(
    $view->next,
    undef,
    'TView->next'
  );
  subtest 'TView->origin' => sub {
    plan tests => 2;
    is( $view->origin->x, 0 );
    is( $view->origin->y, 1 );
  };
  subtest 'TView->size' => sub {
    plan tests => 2;
    is( $view->size->x, 80 );
    is( $view->size->y, 23 );
  };
  subtest 'TView->cursor' => sub {
    plan tests => 2;
    is( $view->cursor->x, 0 );
    is( $view->cursor->y, 0 );
  };
  is(
    $view->grow_mode,
    0,
    'TView->grow_mode'
  );
  is(
    $view->drag_mode,
    DM_LIMIT_LO_Y,
    'TView->drag_mode'
  );
  is(
    $view->help_ctx,
    HC_NO_CONTEXT,
    'TView->help_ctx'
  );
  is(
    $view->state,
    SF_VISIBLE,
    'TView->state'
  );
  is(
    $view->event_mask,
    EV_MOUSE_DOWN | EV_KEY_DOWN | EV_COMMAND,
    'TView->event_mask'
  );
}

#---------------
note 'Commands';
#---------------
# command_enabled, disable_commands, enable_commands, disable_command, 
# enable_command, get_commands, set_commands, set_cmd_state
{
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

#-------------
note 'Inform';
#-------------
# size_limits, get_bounds, get_extent, get_clip_rect, mouse_in_view
{
  my $bounds = TRect->init(0,1,80,24);
  isa_ok($bounds, TRect->class);
  my $view = TView->init($bounds);
  my ($min, $max) = ( TPoint->new(), TPoint->new() );
  isa_ok($view, TView->class);
  isa_ok($min, TPoint->class);
  isa_ok($max, TPoint->class);
  $view->size_limits($min, $max);
  subtest 'TView->size_limits' => sub {
    plan tests => 4;
    is( $min->x, 0 );
    is( $min->y, 0 );
    cmp_ok( $max->x, '>', 80 );
    cmp_ok( $max->y, '>', 24 );
  };

  $bounds->assign(0,0,0,0);
  $view->get_bounds($bounds);
  subtest 'TView->get_bounds' => sub {
    plan tests => 4;
    is( $bounds->a->x, 0 );
    is( $bounds->a->y, 1 );
    is( $bounds->b->x, 80 );
    is( $bounds->b->y, 24 );
  };
  
  my $extent = TRect->new();
  isa_ok($extent, TRect->class);
  $view->get_extent($extent);
  subtest 'TView->get_extent' => sub {
    plan tests => 4;
    is( $extent->a->x, 0 );
    is( $extent->a->y, 0 );
    is( $extent->b->x, 80 );
    is( $extent->b->y, 23 );
  };

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

#-------------
note 'Modify';
#-------------
# locate, drag_view, calc_bounds, change_bounds, grow_to, move_to, set_bounds
{
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
  subtest 'TView->set_bounds' => sub {
    plan tests => 4;
    is( $view->origin->x, 0 );
    is( $view->origin->y, 1 );
    is( $view->size->x, 80 );
    is( $view->size->y, 23 );
  };

  $bounds->assign(0,0,80,25);
  $view->change_bounds($bounds);
  subtest 'TView->change_bounds' => sub {
    plan tests => 4;
    is( $view->origin->x, 0 );
    is( $view->origin->y, 0 );
    is( $view->size->x, 80 );
    is( $view->size->y, 25 );
  };

  $bounds->assign(0,1,80,24);
  $view->locate($bounds);
  subtest 'TView->locate' => sub {
    plan tests => 4;
    is( $view->origin->x, 0 );
    is( $view->origin->y, 1 );
    is( $view->size->x, 80 );
    is( $view->size->y, 23 );
  };

  $view->move_to(0,0);
  $view->grow_to(80,25);
  subtest 'TView->move_to && TView->grow_to' => sub {
    plan tests => 4;
    is( $view->origin->x, 0 );
    is( $view->origin->y, 0 );
    is( $view->size->x, 80 );
    is( $view->size->y, 25 );
  };

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
  subtest 'TView->calc_bounds' => sub {
    plan tests => 4;
    is( $bounds->a->x, 0 );
    is( $bounds->a->y, 0 );
    is( $bounds->b->x, 80 );
    is( $bounds->b->y, 23 );
  };

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
    todo_skip 'TView->drag_view', 1;
    $view->drag_view($event, $mode, $bounds, $min, $max);
    subtest 'TView->drag_view' => sub {
      plan tests => 4;
      is( $view->origin->x, 0 );
      is( $view->origin->y, 0 );
      is( $view->size->x, 40 );
      is( $view->size->y, 23 );
    };
  }

  note 'Delete temporary owner';
  $view->{owner} = undef;
  ok(
    !defined $view->owner,
    '!defined TView->owner'
  );
}

done_testing();

