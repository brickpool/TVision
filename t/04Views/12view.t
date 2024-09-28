use 5.014;
use warnings;
use constant::boolean;
use Scalar::Util qw( refaddr );

use Test::More tests => 43;
use Test::Exception;

BEGIN {
  note 'use Objects, Drivers, Views';
  use_ok 'TurboVision::Objects::Point';
  use_ok 'TurboVision::Objects::Rect';
  use_ok 'TurboVision::Objects::Types', qw(
    TPoint
    TRect
  );
  use_ok 'TurboVision::Drivers::Const', qw( :evXXXX );
  use_ok 'TurboVision::Drivers::Event';
  use_ok 'TurboVision::Drivers::Types', qw( TEvent );
  use_ok 'TurboVision::Views::Common', qw( $error_attr );
  use_ok 'TurboVision::Views::Const', qw(
    :cmXXXX
    :hcXXXX
    :ofXXXX
    :sfXXXX
  );
  use_ok 'TurboVision::Views::View';
  use_ok 'TurboVision::Views::Types', qw( TView );
}

#-------------
note 'Helper';
#-------------
# get_help_ctx, valid, awaken, end_modal, execute
{
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
    sub { $view->awaken },
    'TView->awaken'
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

#-----------
note 'Data';
#-----------
# data_size, get_data, set_data
{
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

#------------
note 'State';
#------------
# get_state, select, set_state
{
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

  $view->set_state(SF_VISIBLE, FALSE);
  ok(
    !$view->get_state(SF_VISIBLE),
    'TView->set_state'
  );
}

#------------
note 'Event';
#------------
# clear_event, event_avail, get_event, handle_event, put_event
{
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

#------------
note 'Color';
#------------
# get_color, get_palette
{
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
    $error_attr, # 0xcf
    'TView->get_color'
  );
}

done_testing();