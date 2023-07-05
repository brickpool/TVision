=pod

=head1 NAME

TView - Parent of all visible objects in Turbo Vision.

=head1 SYNOPSIS

  use TurboVision::Views;
  ...
  my $obj = TView->init($bounds);

=cut

package TurboVision::Views::View;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use Function::Parameters {
  factory => {
    defaults    => 'classmethod_strict',
    shift       => '$class',
    name        => 'required',
  },
},
qw(
  method
);

use Moose;
use MooseX::Types::Moose qw( :all );
use MooseX::HasDefaults::RO;
use namespace::autoclean;

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:fpc';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Data::Alias qw( alias );
use List::Util qw( min max );
use Try::Tiny;

use TurboVision::Const qw(
  :bool
  :limits
);
use TurboVision::Drivers::Const qw(
  :evXXXX
  :kbXXXX
);
use TurboVision::Drivers::Event;
use TurboVision::Drivers::EventManager qw( :kbd );
use TurboVision::Drivers::Types qw( TEvent );
use TurboVision::Drivers::Utility qw( :move );
use TurboVision::Objects::Common qw( fail );
use TurboVision::Objects::Point;
use TurboVision::Objects::Rect;
use TurboVision::Objects::Stream;
use TurboVision::Objects::StreamRec;
use TurboVision::Objects::Types qw(
  TObject
  TPoint
  TRect
  TStream
  TStreamRec
);
use TurboVision::Views::Common qw(
  :vars
  :private
);
use TurboVision::Views::Const qw(
  :cmXXXX
  :dmXXXX
  :gfXXXX
  :hcXXXX
  :ofXXXX
  :sfXXXX
  MAX_VIEW_WIDTH
);
use TurboVision::Views::Types qw(
  TCommandSet
  TGroup
  TView
);

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

use Moose::Exporter;
Moose::Exporter->setup_import_methods(
  as_is => [ 'RView' ],
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<TView> is the parent of all visible objects in Turbo Vision.

Generally, you will directly instantiate and use one of the descendants:

I<TBackground>, I<TButton>, I<TCluster>, I<TFrame>, I<TGroup>, I<THistory>,
I<TInputLine>, I<TListViewer>, I<TMenuView>, I<TStatusLine>, I<TStatusText>,
and their respective descendants.

See the descriptions for objects listed above.

B<Commonly Used Features>

I<TView> provides much of the functionality of all visible objects in Turbo
Vision.

As a consequence, I<TView> has the most methods of any Turbo Vision
object.

While many of the methods are primarly used internally and to
create new descendant-type objects, most applications will encounter at
least the following I<TView> methods:

L</grow_mode>, L</drag_mode>, L</help_ctx>, L</state>, L</options> and
L</event_mask>.

Commonly used methods include L</block_cursor>, L</clear_event>,
L</command_enabled>, L</data_size>, L</disable_commands>, L</draw>,
L</draw_view>, L</enable_commands>, L</get_color>, L</get_commands>,
L</get_help_ctx>, L</get_palette>, L</get_state>, L</hide_cursor>,
L</normal_cursor>, L</select>, L</set_commands>, L</set_state>, L</show>,
L</show_cursor>, L</valid>, L</write_line> and L</write_str>.

=head2 Class

public class I<< TView >>

Turbo Vision Hierarchy.

  TObject
    TView

=cut

package TurboVision::Views::View {

  extends TObject->class;

  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Constants

=over

=item I<RView>

  constant RView = < TStreamRec >;

Defining a registration record constant for I<TView>.

I<TView> is registered with I<< TStreamRec->register_type(RView) >>.

=cut

  use constant RView => TStreamRec->new(
    obj_type  => 1,                                       # Register id = 1
    vmt_link  => __PACKAGE__,                             # Alt style VMT link
    load      => 'load',                                  # Object load method
    store     => 'store',                                 # Object store method
  );

=begin comment

=item I<_ERROR_ATTR>

  constant _ERROR_ATTR = < Int >;

Error colours.

=end comment

=cut

  use constant _ERROR_ATTR => 0xcf;

=back

=cut

  # ------------------------------------------------------------------------
  # Variables --------------------------------------------------------------
  # ------------------------------------------------------------------------

=begin comment

=head2 Variables

=over

=item I<$_static_var2>

  my $static_var2 = < HashRef[TView|Undef|Int] >;

Helper variable for I<TView> methods L</exposed> and L</write_str>.

=end comment

=cut

  my $_static_var2 = {
    target  => undef,
    offset  => 0,
    y       => 0,
  };

=begin comment

=back

=end comment

=cut

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Attributes

=over

=item I<cursor>

  has cursor ( is => rwp, type => TPoint ) = TPoint->new;

Records the position of the display cursor.

=cut

  has 'cursor' => (
    isa       => TPoint,
    default   => sub { TPoint->new() },
    writer    => '_cursor',
  );

=item I<drag_mode>

  param drag_mode ( is => rw, type => Int );

The bits in I<drag_mode> indicate the view's dragging characterisitcs when
dragged with the mouse.

You must directly set a value to I<drag_mode> using the I<dmXXXX> constants.

See I<dmXXXX> constants for more information on these settings.

=cut

  has 'drag_mode' => (
    is        => 'rw',
    isa       => Int,
    required  => 1,
  );

=item I<event_mask>

  param event_mask ( is => rw, type => Int );

Set I<event_mask> to mask off or on the classes of messages that are accepted
for processing by this view.

A value of C<0xffff> means that the view will accept all messages. 

You set I<event_mask>to a combination of the I<evXXXX> constants.

See I<evXXXX> constants.

=cut

  has 'event_mask' => (
    is        => 'rw',
    isa       => Int,
    required  => 1,
  );

=item I<grow_mode>

  has grow_mode ( is = rw, type => Int ) = 0;

The bit settings in I<grow_mode> indicate how the view will change shape when
it is resized.

You must explicitly assign values to I<grow_mode>.

See I<gfXXXX> constants for more information on these bit settings.

=cut

  has 'grow_mode' => (
    is        => 'rw',
    isa       => Int,
    default   => 0,
  );

=item I<help_ctx>

  has help_ctx ( is = rw, type => Int ) = 0;

Holds the view's help context setting.

You must explicitly store a value here unless there is no help, in which case
I<help_ctx> will have a default of I<HC_NO_CONTEXT>.

=cut

  has 'help_ctx' => (
    is      => 'rw',
    isa     => Int,
    default => HC_NO_CONTEXT,
  );

=item I<next>

  field next ( is => rwp, type => TView|Undef );

I<next> maintains a circular list pointing to the next view, in Z-order.

=cut

  has 'next' => (
    isa       => TView|Undef,
    init_arg  => undef,
    writer    => '_next',
  );

=item I<options>

  has options ( is => rw, type => Int ) = 0;

Set I<options> to determine event processing order (I<OF_PRE_PROCESS>,
I<OF_POST_PROCESS>) and to set other attributes defined by the I<ofXXXX>
constants.

=cut

  has 'options' => (
    is        => 'rw',
    isa       => Int,
    default   => 0,
  );

=item I<origin>

  param origin ( is => rwp, type => TPoint );

Describes the upper left corner of the view.

=cut

  has 'origin' => (
    isa       => TPoint,
    required  => 1,
    writer    => '_origin',
  );

=item I<owner>

  field owner ( is => rwp, type => TGroup|Undef );

Points to the I<TGroup> that owns this view.

=cut

  has 'owner' => (
    isa       => TGroup|Undef,
    init_arg  => undef,
    writer    => '_owner',
  );

=item I<size>

  param size ( is => rwp, type => TPoint );

Contains the size of the view.

=cut

  has 'size' => (
    isa       => TPoint,
    required  => 1,
    writer    => '_size',
  );

=item I<state>

  param state ( is => rwp, type => Int );

The I<state> bits retain information about many view options, including the
cursor shape, if the cursor is visible or if the view is selected.

See: I<sfXXXX> constants, L</set_state>, L</get_state>

=cut

  has 'state' => (
    isa       => Int,
    required  => 1,
    writer    => '_state',
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => TView;

=head2 Constructors

=over

=item I<init>

  factory init(TRect $bounds) : TView

Creates an initializes a I<TView> object and places it according to the Bounds
parameter.

You may wish to directly assign values other than defaults, to L</state>,
L</options>, L</event_mask>, L</grow_mode> and L</drag_mode>.

=cut

  factory init(TRect $bounds) {
    return $class->new(                                   # Call ancestor
      drag_mode   => DM_LIMIT_LO_Y,                       # Default drag mode
      help_ctx    => HC_NO_CONTEXT,                       # Clear help context
      state       => SF_VISIBLE,                          # Default state
      event_mask  => EV_MOUSE_DOWN                        # Default event masks
                   + EV_KEY_DOWN
                   + EV_COMMAND,
      origin      => $bounds->a,                          # Set view bounds
      size        => $bounds->b - $bounds->a,
    );
  };

=item I<load>

  factory $class->load(TStream $s)

Creates and reads a view from stream I<$s>.

=cut

  factory load(TStream $s) {
    my $read = sub {
      my $type = shift;
      SWITCH: for( $type ) {
        /byte/ && do {
          $s->read(my $buf, byte->size);
          return byte( $buf )->unpack;
        };
        /integer/ && do {
          $s->read(my $buf, integer->size);
          return integer( $buf )->unpack;
        };
        /word/ && do {
          $s->read(my $buf, word->size);
          return word( $buf )->unpack;
        };
      };
      return undef;
    };

    try {
      my $origin = TPoint->new(
        x => 'integer'->$read,                            # Read origin x value
        y => 'integer'->$read,                            # Read origin y value
      );
      my $size = TPoint->new(
        x => 'integer'->$read,                            # Read view x size
        y => 'integer'->$read,                            # Read view y size
      );
      my $cursor = TPoint->new(
        x => 'integer'->$read,                            # Read cursor x size
        y => 'integer'->$read,                            # Read cursor y size
      );
      my $grow_mode   = 'byte'->$read;                    # Read growmode flags
      my $drag_mode   = 'byte'->$read;                    # Read dragmode flags
      my $help_ctx    = 'word'->$read;                    # Read help context
      my $state       = 'word'->$read;                    # Read state masks
      my $options     = 'word'->$read;                    # Read options masks
      my $event_mask  = 'word'->$read;                    # Read event masks
      return $class->new(                                 # Call ancestor
        origin      => $origin,
        size        => $size,
        cursor      => $cursor,
        grow_mode   => $grow_mode,
        drag_mode   => $drag_mode,
        help_ctx    => $help_ctx,
        state       => $state,
        options     => $options,
        event_mask  => $event_mask,
      );
    }
    catch {
      return fail;
    }
  };

=back

=cut

  # ------------------------------------------------------------------------
  # Destructors ------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Destructors

=over

=item I<DEMOLISH>

  method DEMOLISH()

Deletes the view after erasing it from the screen.

=cut

  method DEMOLISH(@) {
    $self->hide();                                        # Hide the view
    $self->owner->delete($self)                           # Delete from owner
      if $self->owner;
    return;
  }

=back

=cut

  # ------------------------------------------------------------------------
  # TView ------------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Methods

=over

=item I<block_cursor>

  method block_cursor()

Changes the cursor to the solid block cursor by setting the I<SF_CURSOR_INS>
bit in the I<state> attribute.

See L</normal_cursor>

=cut

  method block_cursor() {
    $self->set_state(SF_CURSOR_INS, _TRUE);               # Set insert mode
    return;
  }

=item I<calc_bounds>

  method calc_bounds(TRect $bounds, TPoint $delta)

I<calc_bounds> is used internally to resize and shape this view in the case
that the L</owner>'s view was changed in size.

=cut

  method calc_bounds(TRect $bounds, TPoint $delta) {
    my ($s, $d, $min, $max);
    
    my $range = sub {
      my ($val, $min, $max) = @_;
      return $min                                         # Value below min
          if $val < $min;
      return $max                                         # Value above max
          if $val > $max;
      return $val;                                        # Accept value
    };

    my $grow_i = sub(\$) {
      alias my $i = $_[0];
      if ( not $self->grow_mode & GF_GROW_REL ) {
        $i -= $d;
      }
      elsif ( $s == $d ) {
        $i = 1;
      }
      else {
        $i = int(                                         # Calc grow value
          ($i * $s + ($s - $d) >> 1) / ($s - $d)
        )
      }
    };

    $self->get_bounds($bounds);                           # Get bounds
    return                                                # No grow flags exits
        if $self->grow_mode == 0;

    $s = $self->owner->size->x;                           # Set initial size
    $d = $delta->x;                                       # Set initial delta
    $grow_i->($bounds->a->{x})                            # Grow left side
      if $self->grow_mode & GF_GROW_LO_X;
    $grow_i->($bounds->b->{x})                            # Grow right side
      if $self->grow_mode & GF_GROW_HI_X;
    $bounds->b->x # =
      ( $bounds->a->x + MAX_VIEW_WIDTH )                  # Check values
        if $bounds->b->x - bounds->a->x > MAX_VIEW_WIDTH;

    $s = $self->owner->size->y;                           # Set initial size
    $d = $delta->y;                                       # Set initial delta
    $grow_i->($bounds->a->{y})                            # Grow top side
      if $self->grow_mode & GF_GROW_LO_Y;
    $grow_i->($bounds->b->{y})                            # Grow lower side
      if $self->grow_mode & GF_GROW_HI_Y;

    $self->size_limits($min, $max);                       # Check sizes
    $bounds->b->x # =                                     # Set right side
    (
      $bounds->a->x
      + $range->($bounds->b->x - $bounds->a->x, $min->x, $max->x)
    );
    $bounds->b->y # =                                     # Set lower side
    (
      $bounds->a->y
      + $range->($bounds->b->y - $bounds->a->y, $min->y, $max->y)
    );

    return;
  }

=item I<change_bounds>

  method change_bounds(TRect $bounds)

This internal procedure repositions the view.

=cut

  method change_bounds(TRect $bounds) {
    $self->set_bounds($bounds);                           # Set new bounds
    $self->draw_view;                                     # Draw the view
    return;
  }

=item I<clear_event>

  method clear_event(TEvent $event)

In your L</handle_event> methods or overridden L</handle_event> methods,
whenever you have finished processing an event, you must signal that the event
is finished by calling I<clear_event>, which sets
I<< $event->what( EV_NOTHING ) >>; and I<< $event->info_ptr( $self ) >> so that
other views can determine who it was that process the event.

=cut

  method clear_event(TEvent $event)  {
    $event->what(EV_NOTHING);                             # Clear the event
    $event->info_ptr($self);                              # Set us as handler
    return;
  }

=item I<command_enabled>

  method command_enabled(Int $command) : Bool

Use I<command_enabled> to check if a specific command is currently enabled or
allowed.

Pass the I<cmXXXX> value as the I<$command> parameter and I<command_enabled>
will return True if the command is available now, or False if the command has
been disabled.

=cut

  method command_enabled(Int $command) {
    no if $] >= 5.018, warnings => 'experimental::smartmatch';
    return $command > 255
        || $command ~~ $cur_command_set;                  # Check command
  }

=item I<data_size>

  method Int data_size()

Used in conjunction with L</get_data> and L</set_data> to copy the views data to
and from a data record.

See L</get_data>, L</set_data>

=cut

  method data_size() {
    return 0;                                             # Transfer size
  }

=item I<disable_commands>

  method disable_commands(TCommandSet $commands)
  method disable_commands(ArrayRef[Int] $commands)

I<$commands> is a reference containing a set of commands, specified by their
I<cmXXXX> constant values, to be disabled.

Calling I<disable_commands> causes these I<$commands> to become greyed out on
the menus and status line.

See L</enable_commands>

=cut

  method disable_commands(TCommandSet|ArrayRef[Int] $commands) {
    my $cmds = is_ArrayRef($commands)
             ? TCommandSet->init($commands)
             : $commands
             ;
    $command_set_changed ||=                              # Set changed flag
      $cur_command_set * $cmds != [];
    $cur_command_set = $cur_command_set - $cmds;          # Update command set
    return;
  }

=item I<drag_view>

  method drag_view(TEvent $event, Int $mode, TRect $limits, TPoint $min_size, TPoint $max_size)

I<drag_view> handles redrawing the view while it is being dragged across the
string.

I<$limits> defines the rectangle in which the view can be dragged, and
I<$min_size> and I<$max_size> set the minimum and maximum sizes to which the
view can be resized.

=cut

  method drag_view(TEvent $event, Int $mode, TRect $limits, TPoint $min_size,
                   TPoint $max_size)
  {
    my ( $p, $s ) = ( TPoint->new(), TPoint->new() );
    my $save_bounds;

    my $move_grow = sub {
      my ( $p, $s ) = @_;

      $s->x # =
        ( min( max($s->x, $min_size->x), $max_size->x ) );
      $s->y # =
        ( min( max($s->y, $min_size->y), $max_size->y ) );

      $p->x # =
        ( min( max($p->x, $limits->a->x - $s->x+1), $limits->b->x-1 ) );
      $p->y # =
        ( min( max($p->y, $limits->a->y - $s->y+1), $limits->b->y-1 ) );

      $p->x # =
        ( max($p->x, $limits->a->x) )
          if $mode & DM_LIMIT_LO_X;

      $p->y # =
        ( max($p->y, $limits->a->y) )
          if $mode & DM_LIMIT_LO_Y;

      $p->x # =
        ( min($p->x, $limits->b->x - $s->x) )
          if $mode & DM_LIMIT_HI_X;

      $p->y # =
        ( min($p->y, $limits->b->y - $s->y) )
          if $mode & DM_LIMIT_HI_Y;

      my $r = TRect->init( $p->x, $p->y, $p->x + $s->x, $p->y + $s->y );
      $self->locate($r);
    };
    
    my $change = sub {
      my ( $dx, $dy ) = @_;
      if ( $mode & DM_DRAG_MOVE and not get_shift_state & 0x03 ) {
        $p->x # =
          ( $p->x + $dx );
        $p->y # =
          ( $p->y + $dy );
      }
      elsif ( $mode & DM_DRAG_MOVE and get_shift_state & 0x03 ) {
        $s->x # =
          ( $s->x + $dx );
        $s->y # =
          ( $s->y + $dy );
      }
    };

    my $update = sub {
      my ($x, $y) = @_;
      if ( $mode & DM_DRAG_MOVE ) {
        $p->x($x);
        $p->y($y);
      }
    };

    $self->set_state(SF_DRAGGING, _TRUE);
    if ( $event->what == EV_MOUSE_DOWN ) {
      if ( $mode & DM_DRAG_MOVE ) {
        $p = $self->origin - $event->where;
        do {
          $event->where += $p;
          $move_grow->($event->where, $self->size);
        } while ( $self->mouse_event($event, EV_MOUSE_MOVE) );
        # we need to process the mouse-up event, since not all terminals
        # send drag events.
        $event->where += $p;
        $move_grow->($event->where, $self->size);
      }
      else {
        $p = $self->size - $event->where;
        do {
          $event->where += $p;
          $move_grow->($self->origin, $event->where);
        } while ( $self->mouse_event($event, EV_MOUSE_MOVE) );
        # we need to process the mouse-up event, since not all terminals
        # send drag events.
        $event->where += $p;
        $move_grow->($self->origin, $event->where);
      }
    }
    else {
      $self->get_bounds($save_bounds);
      do {
        $p->copy($self->origin);
        $s->copy($self->size);
        $self->key_event($event);
        SWITCH: for ( $event->key_code & 0xff00 ) {
          $_ == KB_LEFT       && $change->( -1, 0 );
          $_ == KB_RIGHT      && $change->( 1, 0 );
          $_ == KB_UP         && $change->( 0, -1 );
          $_ == KB_DOWN       && $change->( 0, 1 );
          $_ == KB_CTRL_LEFT  && $change->( -8, 0 );
          $_ == KB_CTRL_RIGHT && $change->( 8, 0 );
          $_ == KB_HOME       && $update->( $limits->a->x, $p->y );
          $_ == KB_END        && $update->( $limits->b->x - $s->x, $p->y );
          $_ == KB_PG_UP      && $update->( $p->x, $limits->a->y );
          $_ == KB_PG_DN      && $update->( $p->x, $limits->b->y - $s->y );
        }
        $self->move_grow($p, $s);
      } while ( $event->key_code != KB_ENTER && $event->key_code != KB_ESC );
      $self->locate($save_bounds)
        if $event->key_code == KB_ESC;
    }
    $self->set_state(SF_DRAGGING, _FALSE);
    
    return;
  }

=item I<draw>

  method draw()

The I<draw> method is the only method that should write data to the view's
screen area.

Any view that you create, including descendants such as I<TWindow> or
I<TApplication>, must override the I<draw> method in order to display
their output on the screen.

Generally, your I<draw> method must keep track of where the screen image is
relative to its internal data structure.

For example, if your code implements a text editor, you do not need to draw
all 500 lines that are in the current file.

Instead, I<draw> would update only the lines that are actually visible.

Sometimes you do not need to redraw the entire view because, perhaps, only a
portion of the screen was overwritten by another view such as a dialog.

Call L</get_clip_rect> to fetch the coordinates of the minimum area that needs
updating.

The use of L</get_clip_rect> can noticeably improve performance by minimizing
the amount of time spent updating the screen.

See L</draw_view>, L</get_clip_rect>

=cut

  method draw() {
    my $b = [];
    move_char($b, ' ', $self->get_color(1), $self->size->x);
    $self->write_line(0, 0, $self->size->x, $self->size->y, $b);
    return;
  }

=item I<draw_view>

  method draw_view()

I<draw_view> is the preferred method to call when you need to update the view.

That's because I<draw_view> makes a check to determine if the view is exposed
(not hidden behind another view) before attempting to call L</draw>.

L</draw> doesn't care if the view is visible since Turbo Vision will
automatically clip away text that doesn't currently appear in a view.

See L</draw>

=cut

  method draw_view() {
    if ( $self->exposed ) {
      $self->lock_screen_update; # don't update the screen yet
      $self->draw;
      $self->unlock_screen_update;
      $self->draw_screen_buf(_FALSE);
      $self->draw_cursor;
    }
    return;
  }

=item I<enable_commands>

  method enable_commands(TCommandSet $commands)
  method enable_commands(ArrayRef[Int] $commands)

<$commands> is a reference containing a set of commands, specified by their
I<cmXXXX> constant values, to be enabled.

I<enable_commands> is the inverse of L</disable_commands> and restores commands
to an operable state.

=cut

  method enable_commands(TCommandSet|ArrayRef[Int] $commands) {
    my $cmds = is_ArrayRef($commands)
             ? TCommandSet->init($commands)
             : $commands
             ;
    $command_set_changed ||=                              # Set changed flag
      $cur_command_set * $cmds != [];
    $cur_command_set = $cur_command_set + $cmds;          # Update command set
    return;
  }

=item I<end_modal>

  method end_modal(Int $command)

Used internally in conjunction with I<exec_view> for displaying modal views,
such as dialogs, to terminate the modal view.

See I<< TGroup->end_modal >>, I<< TGroup->execute >>, I<< TGroup->exec_view >>

=cut

  method end_modal(Int $command) {
    my $p = $self->top_view;                              # Get top view
    $p->end_modal($command)                               # End modal operation
      if defined $p;
    return;
  }

=item I<event_avail>

  method event_avail() : Bool

Returns True if an event is available.

=cut

  method event_avail() {
    my $event = TEvent->new();
    $self->get_event($event);                             # Get next event
    $self->put_event($event)                              # Put it back
      if $event->what != EV_NOTHING; 
    return $event->what != EV_NOTHING;                    # Return result
  }

=item I<execute>

  method execute() : Int

I<execute> is overridden in I<TGroup> descendants to provide the event loop that
makes the view a modal view.

See I<< TGroup->end_modal >>, I<< TGroup->execute >>, I<< TGroup->exec_view >>

=cut

  method execute() {
    return CM_CANCEL;                                     # Return cancel
  }

=item I<exposed>

  method exposed() : Bool

If at least some part of the view can be seen on the screen, then I<exposed>
returns True.

If the view is completely hidden, then I<exposed> returns False.

=cut

  method exposed() {
    if ( $self->state & SF_EXPOSED 
      && $self->size->x > 0
      && $self->size->y > 0
    ) {
      my $ok = _FALSE;
      my $y = 0;
      while ( $y < $self->size->y and not $ok ) {
        $_static_var2->{y} = $y;
        $ok = $self->_do_exposed_rec2(0, $self->size->x, $self);
        $y++;
      }
      return $ok;
    }
    return _FALSE;
  }

=item I<get_bounds>

  method get_bounds()

Returns the upper left and lower right corners of this view in I<$bounds>,
relative to the owner of the view.

=cut

  method get_bounds(TRect $bounds) {
    $bounds->a # =
      ( $self->origin );                                  # Get first corner
    $bounds->b # =
      ( $self->origin + $self->size );                    # Calc corner value
    return;
  }

=item I<get_clip_rect>

  method get_clip_rect(TRect $clip)

Returns the upper left and lower right corners in I<$clip> of the minimum
sized area that needs to be redrawn.

Uses this procedure in L</draw> to help locate only the area on the screen that
needs to be updated.

See L</draw>

=cut

  method get_clip_rect(TRect $clip) {
    $self->get_bounds($clip);                             # Get current bounds
    $clip->intersect($self->owner->_clip)                 # Intersect with owner
      if defined $self->owner;
    $clip->move(- $self->origin->x, - $self->origin->y);  # Sub owner origin
    return;
  }

=item I<get_color>

  method get_color(Int $color) : Int;

I<$color> contains two color indexes, one in the high byte and one in the low
byte.

I<get_color> maps these indexes into the each color palette, in turn, going all
the way back to the palette containing the video color attributes.

These values are then returned in the corresponding high and low bytes of the
result.

=cut

  method get_color(Int $color) {
    my $offset = $self->_colour_ofs;
    my ( $col, $palette, $value );

    $value = 0;                                           # Clear colour value
    if ( $color & 0xff00 ) {                              # High colour req
      $col = word($color)->hi + $offset;                  # Initial offset
      my $view = $self;                                   # Reference to self
      do {
        $palette = $view->get_palette;                    # Get our palette
        if ( defined $palette ) {                         # Palette is valid
          $col = $col <= length $palette
               ? ( unpack 'C*', $palette )[$col]          # Return colour
               : _ERROR_ATTR                              # Error attribute
               ;
        }
        $view = $view->owner;                             # Move up to owner
      } while ( defined $view );                          # Until no owner
      $value = $col << 8;                                 # Translate colour
    }
    if ( $color & 0x00ff ) {
      $col = word($color)->lo + $offset;                  # Initial offset
      my $view = $self;                                   # Reference to self
      do {
        $palette = $view->get_palette;                    # Get our palette
        if ( defined $palette ) {                         # Palette is valid
          $col = $col <= length $palette
               ? ( unpack 'C*', $palette )[$col]          # Return colour
               : _ERROR_ATTR                              # Error attribute
               ;
        }
        $view = $view->owner;                             # Move up to owner
      } while ( defined $view );                          # Until no owner
    }
    else {
      $col = _ERROR_ATTR;                                 # No colour found
    }
    return $value | $col;                                 # Return color
  }

=item I<get_commands>

  method get_commands(TCommandSet $commands)

Use I<get_commands> to fetch a set containing all of the currently enabled
commands.

=cut

  method get_commands(TCommandSet $commands) {
    $commands->copy($cur_command_set);                    # Return command set
    return;
  }

=item I<get_data>

  method get_data(Str $rec)

This method is overridden in descendants to copy the appropriate amount of view
data to I<$rec>.

This method is primarily of interest to dialog box controls.

=cut

  method get_data($) {
    alias my $rec = $_[-1];
    assert( is_Str $rec );
    return;
  }

=item I<get_event>

  method get_event(TEvent $event)

Returns the next event from the event queue (typically called after calling
L</event_avail>).

=cut

  method get_event(TEvent $event) {
    $self->owner->get_event($event)                       # Event from owner
      if defined $self->owner;
    return;
  }

=item I<get_extent>

  method get_extent(TRect $extent)

Similar to L</get_bounds>, except that I<get_extent> sets I<< $extent->a >> =
(0,0) such that I<< $extent->b >>, which is set to L</size>, reflects the total
extent of the view relative to the upper left corner.

=cut

  method get_extent(TRect $extent) {
    $extent->a->x(0);                                     # Zero x field
    $extent->a->y(0);                                     # Zero y field
    $extent->b # =
      ( $self->size );                                    # Return size
    return;
  }

=item I<get_help_ctx>

  method get_help_ctx() : Int

Returns the L</help_ctx> value. 

=cut

  method get_help_ctx() {
    return HC_DRAGGING                                    # Return dragging
        if $self->state & SF_DRAGGING;                    # Dragging state check
    return $self->help_ctx                                # Return help context
  }

=item I<get_palette>

  method get_palette() : TPalette|Undef

The default I<get_palette> returns C<undef>, so most views will elect to
override this function such that it returns a I<TPalette> (= packed I<Str>) to
the color palette for this view.

=cut

  method get_palette() {
    return undef;                                         # Return undef
  }

=item I<get_peer_view_ptr>

  method get_peer_view_ptr(TStream $s, Ref $r)

Used by L</load> when certain objects need to load a peer view, I<$r>, from
stream I<$s>, such as a list box needing to load it scroll bar object.

=cut

  method get_peer_view_ptr(TStream $s, Ref $r) {
    my $index = 0;                                        # Zero index value
    $s->read($index, integer()->size);                    # Read view index
    if ( $index == 0 or not defined $_owner_group ) {     # Check for peer views
      $r = \undef;                                        # Return undef
    }
    else {
      $r = $_fixup_list->[$index];                        # New view reference
      $_fixup_list->[$index] = \$r;                       # Patch this reference
    }
    return;
  }

=item I<get_state>

  method get_state(Int $a_state) : Bool

Parameter I<$a_state> can be set to multiple combinations of the I<sfXXXX>
constants and returns True if the the indicated bits are set in the L</state>
variable.

See L</state>, I<sfXXXX> constants

=cut

  method get_state(Int $a_state) {
    return ($self->state & $a_state) == $a_state;         # Check states equal
  }

=item I<grow_to>

  method grow_to(Int $x, Int $y)

Calls L</locate> to adjust the size of the view.

=cut

  method grow_to(Int $x, Int $y) {
    my $rect = TRect->init(                               # Assign area
      $self->origin->x,
      $self->origin->y,
      $self->origin->x + $x,
      $self->origin->y + $y
    );
    $self->locate($rect);                                 # Locate the view
    return;
  }

=item I<handle_event>

  method handle_event(TEvent $event)

Every view must override the I<handle_event> method.

This is where events are recognized and parceled out to make the view come
alive.

For an example, see I<TVSHELL8.PAS>, I<< TShell.HandleEvent >>, in the Borland
Pascal Developer's Guide.

See I<evXXXX> constants, I<cmXXXX> constants
     
=cut

  method handle_event(TEvent $event) {
    if ( $event->what == EV_MOUSE_DOWN ) {                # Mouse down event
      $self->clear_event($event)                          # Handle the event
        if !($self->state & (SF_SELECTED | SF_DISABLED))  # Not selected/disabled
        && $self->options & OF_SELECTABLE                 # View is selectable
        && (
          !$self->focus                                   # Not view with focus
            ||
          !($self->options & OF_FIRST_CLICK)              # Not 1st click select
        );
    }
    return;
  }

=item I<hide>

  method hide()

Hides the view.

See L</show>

=cut

  method hide() {
    $self->set_state(SF_VISIBLE, _FALSE)                  # Hide the view
      if $self->state & SF_VISIBLE;                       # View is visible
    return;
  }

=item I<hide_cursor>

  method hide_cursor()

Hides the cursor.

See L</show_cursor>

=cut

  method hide_cursor() {
    $self->set_state(SF_CURSOR_VIS, _FALSE);              # Hide the cursor
    return;
  }

=item I<key_event>

  method key_event(TEvent $event)

I<key_event> ignores all incoming events until it gets an I<EV_KEY_DOWN> event,
and it returns that event.

=cut

  method key_event(TEvent $event) {
    do {
      $self->get_event($event);                           # Get next event
    } while ( $event->what != EV_KEY_DOWN );              # Wait till keydown
    return;
  }

=item I<locate>

  method locate(TRect $bounds)

Changes the boundaries of the view and redisplays the view on the screen.

=cut

  method locate(TRect $bounds) {
    my $range = sub {
      my ($val, $min, $max) = @_;
      return $min                                     # Value to small
        if $val < $min;
      return $max                                     # Value to large
        if $val > $max;
      return $val;                                    # Value is okay
    };

    $self->size_limits(my $min, my $max);             # Get size limits
    $bounds->b->x # =                                 # X bound limit
    (
      $bounds->a->x
      + $range->( $bounds->b->x - $bounds->a->x, $min->x, $max->x )
    );
    $bounds->b->y # =                                 # Y bound limit
    (
      $bounds->a->y
      + $range->( $bounds->b->y - $bounds->a->y, $min->y, $max->y )
    );
    $self->get_bounds(my $r);                         # Current bounds
    if ( $bounds != $r ) {                            # Size has changed
      $self->change_bounds($bounds);                  # Change bounds
      if ( $self->state & SF_VISIBLE                  # View is visible
        && $self->state & SF_EXPOSED                  # Check view exposed
        && defined $self->owner
      ) {
        if ( $self->state & SF_SHADOW ) {
          $r->union($bounds);
          $r->b += $shadow_size;
        }
        $self->_draw_under_rect($r, undef);
      }
    }
    return;
  }

=item I<make_first>

  method make_first()

Moves this view to the first position (closest to the screen) in the owner's
Z-ordered list of views.

=cut

  method make_first() {
    $self->put_in_front_of($self->owner->first)           # Float to the top
      if defined $self->owner;                            # Must have owner
    return;
  }

=item I<make_global>

  method make_global(TPoint $source, TPoint $dest)

Use I<make_global> (see also L</make_local>) to convert I<$source>, which
contains view relative coordinates, to screen coordinates.

The converted value is returned in I<$dest>.

=cut

  method make_global(TPoint $source, TPoint $dest) {
    my $cur = $self;
    $dest->copy($source);
    do {
      $dest += $cur->origin;
      $cur = $cur->owner;
    } while ( defined $cur );
    return;
  }

=item I<make_local>

  method make_local(TPoint $source, TPoint $dest)

Converts the screen coordinates into view relative coordinates.

See L</make_global>.

=cut

  method make_local(TPoint $source, TPoint $dest) {
    my $cur = $self;
    $dest->copy($source);
    do {
      $dest->x # =
        ( $dest->x - $cur->origin->x );
      last
        if $dest->x < 0;
      $dest->y # =
        ( $dest->y - $cur->origin->y );
      last
        if $dest->y < 0;
      $cur = $cur->owner;
    } while ( defined $cur );
    return;
  }

=item I<mouse_event>

  method mouse_event(TEvent $event, Int $mask) : Bool

I<$mask> is an I<EV_MOUSE> event.

I<mouse_event> sets I<$event> to the next mouse event and returns True if the
I<< $event->what >> field matches I<$mask>, and False if when I<EV_MOUSE_UP>
occurs.

Typically, this function is called when a mouse is being dragged.

To process the dragging operation, keep calling this routine until it returns
False, meaning that the mouse button has been let up.

=cut

  method mouse_event(TEvent $event, Int $mask) {
  }

=item I<mouse_in_view>

  method mouse_in_view(TPoint $mouse) : Bool

If the point described by I<$mouse> (in screen coordinates) lies within this
view, then I<mouse_in_view> returns True.

=cut

  method mouse_in_view(TPoint $mouse) {
  }

=item I<move_to>

  method move_to(Int $x, Int $y)

Keeping the view the same size, I<move_to> moves the upper left corner, and
hence the entire view, to the new point I<($x,$y)>.

=cut

  method move_to(Int $x, Int $y) {
    return;
  }

=item I<next_view>

  method next_view() : TView|Undef

I<next_view> returns a Reference to the next view, in sequence, in the owner's
list of views, or C<undef> if it has reached the end of the list.

=cut

  method next_view() {
    return;
  }

=item I<normal_cursor>

  method normal_cursor()

Sets the screen cursor to an underscore-style cursor.

See L</block_cursor>.

=cut

  method normal_cursor() {
    return;
  }

=item I<prev>

  method prev() : TView

I<prev> returns a reference to the previous view, in sequence, in the owner's
list of views, and cycles back to the beginning of the list if it has reached
the end.

=cut

  method prev() {
  }

=item I<prev_view>

  method prev_view() : TView|Undef

Identical to L</prev> except that if I<prev_view> reaches the beginning of
the view list, I<prev_view> returns C<undef>.

=cut

  method prev_view() {
  }

=item I<put_event>

  method put_event(TEvent $event)

Using I<put_event>, you can force one and only one event to be inserted as the
next event in the event queue.

I<$event> will become the next event retrieved by L</get_event>.

=cut

  method put_event(TEvent $event) {
    return;
  }

=item I<put_in_front_of>

  method put_in_front_of(TView $target)

Where I<$target> is any view in this view's owner's view list,
I<put_in_front_of> moves this view to be placed directly in front of I<$target>.

=cut

  method put_in_front_of(TView $target) {
    return;
  }

=item I<put_peer_view_ptr>

  method put_peer_view_ptr(TStream $s, TView $r)

The L</store> method calls this routine to write the "peer" view object I<$r>
to stream I<$s>.

=cut

  method put_peer_view_ptr(TStream $s, TView $r) {
    return;
  }

=item I<select>

  method select()

I<select> makes this view the active view in the group, and if the owning group
is on the focused chain, then this view becomes the focused view.

=cut

  method select() {
    return;
  }

=item I<set_bounds>

  method set_bounds(TRect $bounds)

This is an internal routine called by L</change_bounds>.

=cut

  method set_bounds(TRect $bounds) {
    return;
  }

=item I<set_cmd_state>

  method set_cmd_state(TCommandSet $commands, Bool $enable)
  method set_cmd_state(ArrayRef[Int] $commands, Bool $enable)

Depending on I<$enable> the current list of commands is expanded
(I<$enable> = true) or reduced (I<$enable> = false) to the set passed in the
parameter I<$commands>.

See L</enable_commands>, L</disable_commands>

=cut

  method set_cmd_state(TCommandSet|ArrayRef[Int] $commands, Bool $enable) {
    if ($enable) {
      $self->enable_commands($commands);
    }
    else {
      $self->disable_commands($commands);
    }
    return;
  }

=item I<set_commands>

  method set_commands(TCommandSet $commands)

Sets the currently list of enabled commands to the set passed in the
I<$commands> parameter.

See L</enable_commands>, L</disable_commands>

=cut

  method set_commands(TCommandSet $commands) {
    return;
  }

=item I<set_cursor>

  method set_cursor(Int $x, Int $y)

Moves the screen cursor to I<($x,$y)> where I<$x> and I<$y> are local
coordinates.

=cut

  method set_cursor(Int $x, Int $y) {
    return;
  }

=item I<set_data>

  method set_data(Str $rec)

Copies L</data_size> bytes from I<$rec> to the view's data fields.

See L</data_size>, L</get_data>

=cut

  method set_data(Str $rec) {
    return;
  }

=item I<set_state>

  method set_state(Int $a_state, Bool $enable)

Use I<set_state> to either set or clear bits in the L</state> variable.

If I<$enable> is True, then the bits specified by I<$a_state> are set, and
if I<$enable> is False, then the bits specified by
I<$a_state> are cleared.

=cut

  method set_state(Int $a_state, Bool $enable) {
    return;
  }

=item I<show>

  method show()

Causes the view to be displayed.

See L</hide>

=cut

  method show() {
    $self->set_state(SF_VISIBLE, _TRUE)                   # Show the view
      if not $self->state & SF_VISIBLE;                   # View not visible
    return;
  }

=item I<show_cursor>

  method show_cursor()

Makes the screen cursor visible (the default condition is a hidden cursor).

=cut

  method show_cursor() {
    $self->set_state(SF_CURSOR_VIS, _TRUE);               # Show the cursor
    return;
  }

=item I<show_cursor>

  method size_limits(TPoint $min, TPoint $max)

Sets I<$min> to (0,0) and I<$max> to I<< $self->owner->size >>.

=cut

  method size_limits(TPoint $min, TPoint $max) {
    $min->x(0);                                           # Zero x minimum
    $min->y(0);                                           # Zero y minimum
    if ( defined $self->owner ) {
      $max->copy($self->owner->size);
    }
    else {                                                # Max owner size
      $max->x # =
        ( _INT16_MAX );                                   # Max possible x size
      $max->y # =
        ( _INT16_MAX );                                   # Max possible y size
    }
    return;
  }

=item I<store>

  method store(TStream $s)

Writes I<$self> view to stream <$s>.

=cut

  method store(TStream $s) {
    my $write = sub {
      my $type = shift;
      my $value = shift // 0;
      SWITCH: for( $type ) {
        /byte/    && $s->write(    byte($value)->pack,    byte->size );
        /integer/ && $s->write( integer($value)->pack, integer->size );
        /word/    && $s->write(    word($value)->pack,    word->size );
      }
    };

    my $state = $self->state;                             # Hold current state
    $state &= ~(                                          # Clear flags
        SF_ACTIVE
      | SF_SELECTED
      | SF_FOCUSED
      | SF_EXPOSED
    );
    'integer'->$write( $self->origin->x );                # Write view x origin
    'integer'->$write( $self->origin->y );                # Write view x origin
    'integer'->$write( $self->size->x   );                # Write view x size
    'integer'->$write( $self->size->y   );                # Write view x size
    'integer'->$write( $self->cursor->x );                # Write view x cursor
    'integer'->$write( $self->cursor->y );                # Write view x cursor

    'byte'->$write( $self->grow_mode  );                  # Write growmode flags
    'byte'->$write( $self->drag_mode  );                  # Write dragmode flags
    'word'->$write( $self->help_ctx   );                  # Write help context
    'word'->$write( $state            );                  # Write state masks
    'word'->$write( $self->options    );                  # Write options masks
    'word'->$write( $self->event_mask );                  # Write event masks

    return;
  }

=item I<top_view>

  method top_view() : TView

Returns a reference to the view modal view that is on top.

=cut

  method top_view() {
    my $view;
    if ( not defined $_the_top_view ) {                   # Check topmost view
      $view = $self;                                      # Start with us
                                                          # Check if modal
      while ( defined $view and not $view->state & SF_MODAL ) {
        $view = $view->owner;                             # Search each owner
      }
      return $view;                                       # Return result
    }
    return $_the_top_view;                                # Return topview
  }

=item I<valid>

  method valid(Int $command) : Bool

Each view contains a I<valid> method which should be overridden to check for
specific error conditions appropriate to your views.

When I<$command> equals I<CM_VALID>, then the view should return False if some
problem has occurred when instantiating the view.

Use I<valid> to check for any type of errors - its up to you to define what
those error conditions might be.

An example might be a view that after initialization is unable to find its data
file. I<valid> might call an error handling routine to display the error, and
return False.

If I<$command> is not equal to I<CM_VALID>, then I<$command> equals the returns
result from a modal dialog and the view can make specific checks based on this
parameter.

=cut

  method valid(Int $command) {
    return _TRUE;                                         # Simply return true
  }

=back

=cut

  method _draw_under_rect(TRect $r, TView $last_view) {
    $self->owner->_clip->intersect($r);
    $self->owner->_draw_sub_views($self->next_view, $last_view);
    $self->owner->get_extent($self->owner->_clip);
    return;
  }

  method _draw_under_view(Bool $shadow, TView $last_view) {
    $self->get_bounds(my $r);
    $r->b += $shadow_size
      if $shadow;
    $self->_draw_under_rect($r, $last_view);
    return;
  }
  
=head2 Inheritance

Methods inherited from class L<Moose::Object>

  new, BUILDARGS, does, DOES, dump, DESTROY

=cut
  
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Free Vision library.
 Copyright (c) 1996-2000 by Leon de Boer.

 Interface Copyright (c) 1992 Borland International

 The library files are licensed under modified LGPL.

 The creation of subclasses of this LGPL-licensed class is considered to be
 using an interface of a library, in analogy to a function call of a library.
 It is not considered a modification of the original class. Therefore,
 subclasses created in this way are not subject to the obligations that an LGPL
 imposes on licensees.

 POD sections by Ed Mitchell are licensed under modified CC BY-NC-ND.

=head1 AUTHORS

=over

=item *

1996-1999 by Leon de Boer E<lt>ldeboer@attglobal.netE<gt>

=item *

1992 by Ed Mitchell (Turbo Pascal Reference electronic freeware book)

=back

=head1 DISCLAIMER OF WARRANTIES

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.

=head1 MAINTAINER

=over

=item *

2023 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

I<TObject>, 
L<views.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/views.pas>
