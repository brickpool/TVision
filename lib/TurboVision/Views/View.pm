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

use constant::boolean;
use Function::Parameters {
  factory => {
    defaults  => 'classmethod_strict',
    name      => 'required',
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

use Carp;
use Data::Alias qw( alias );
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on': 'off';
use List::Util qw( min max );

use TurboVision::Const qw( :limits );
use TurboVision::Drivers::Const qw(
  :crXXXX
  :evXXXX
  :kbXXXX
);
use TurboVision::Drivers::Event;
use TurboVision::Drivers::EventManager qw( :kbd );
use TurboVision::Drivers::Types qw( 
  TEvent 
  Video
);
use TurboVision::Drivers::Utility qw( :move );
use TurboVision::Drivers::Video;
use TurboVision::Objects::Common qw(
  :tools
  fail
);
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
  TDrawBuffer
  TGroup
  TView
  TVideoBuf
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

=back

=cut

  # ------------------------------------------------------------------------
  # Variables --------------------------------------------------------------
  # ------------------------------------------------------------------------

=begin comment

=head2 Variables

=over

=item I<$_static_var1>

  my $_static_var1 = < TDrawBuffer >;

Helper variable for I<TView> method L</write_buf>.

=cut

  my $_static_var1 = [];

=item I<$_static_var2>

  my $_static_var2 = < HashRef[TView|Undef|Int] >;

Helper variable for I<TView> methods L</exposed> and L</write_str>.

=cut

  my $_static_var2 = {
    target  => undef,
    offset  => 0,
    y       => 0,
  };

=back

=end comment

=cut

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Attributes

=over

=item I<cursor>

  has cursor ( is => ro, type => TPoint ) = TPoint->new;

Records the position of the display cursor.

=cut

  has 'cursor' => (
    isa       => TPoint,
    default   => sub { TPoint->new },
  );

=item I<drag_mode>

  param drag_mode ( is => rw, type => Int );

The bits in I<drag_mode> indicate the view's dragging characterisitcs when
dragged with the mouse.

You must directly set a value to I<drag_mode> using the I<dmXXXX> constants.

B<See>: I<dmXXXX> constants for more information on these settings.

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

B<See>: I<evXXXX> constants.

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

B<See>: I<gfXXXX> constants for more information on these bit settings.

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

  param origin ( is => ro, type => TPoint ) = TPoint->new;

Describes the upper left corner of the view.

=cut

  has 'origin' => (
    isa       => TPoint,
    default   => sub { TPoint->new },
  );

=item I<owner>

  field owner ( is => rwp, type => TGroup|Undef ) = undef;

Points to the I<TGroup> that owns this view.

=cut

  has 'owner' => (
    isa       => TGroup|Undef,
    init_arg  => undef,
    writer    => '_owner',
    default   => undef,
  );

=item I<size>

  param size ( is => ro, type => TPoint ) = TPoint->new;

Contains the size of the view.

=cut

  has 'size' => (
    isa       => TPoint,
    default   => sub { TPoint->new },
  );

=item I<state>

  param state ( is => rwp, type => Int );

The I<state> bits retain information about many view options, including the
cursor shape, if the cursor is visible or if the view is selected.

B<See>: I<sfXXXX> constants, L</set_state>, L</get_state>

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

  use constant FACTORY => __PACKAGE__;

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
    my $self = $class->new(                               # Call ancestor
      drag_mode   => DM_LIMIT_LO_Y,                       # Default drag mode
      help_ctx    => HC_NO_CONTEXT,                       # Clear help context
      state       => SF_VISIBLE,                          # Default state
      event_mask  => EV_MOUSE_DOWN                        # Default event masks
                   + EV_KEY_DOWN
                   + EV_COMMAND,
    );
    $self->set_bounds($bounds);                           # Set view bounds
    return $self;
  };

=item I<load>

  factory $class->load(TStream $s)

Creates and reads a view from stream I<$s>.

=cut

  factory load(TStream $s) {
    my $read = sub {
      my $type = shift;
      SWITCH: for( $type ) {
        /byte/ and do {
          $s->read(my $buf, byte->size);
          return byte( $buf )->unpack;
        };
        /integer/ and do {
          $s->read(my $buf, integer->size);
          return integer( $buf )->unpack;
        };
        /word/ and do {
          $s->read(my $buf, word->size);
          return word( $buf )->unpack;
        };
      };
      return undef;
    };

    eval {
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
    } or do {
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
  # Public Methods ---------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Methods

=over

=item I<awaken>

  method awaken()

The default I<< TView->awaken> does nothing.

When a group is loaded from a stream, the last thing the L</load> constructor
does is call the I<awaken> methods of all subviews.

=cut

  method awaken() {
    return;                                               # Abstract method
  }

=item I<block_cursor>

  method block_cursor()

Changes the cursor to the solid block cursor by setting the I<SF_CURSOR_INS>
bit in the I<state> attribute.

B<See>: L</normal_cursor>

=cut

  method block_cursor() {
    $self->set_state(SF_CURSOR_INS, TRUE);               # Set insert mode
    return;
  }

=item I<calc_bounds>

  method calc_bounds(TRect $bounds, TPoint $delta)

The parameter I<calc_bounds> is used internally to resize and shape this view in
the case that the L</owner>'s view was changed in size.

=cut

  method calc_bounds($, TPoint $delta) {
    alias my $bounds = $_[-2];
    confess 'Invalid argument $bounds'
      if not is_TRect $bounds;

    my ($s, $d);
    my ($min, $max) = ( TPoint->new(), TPoint->new() );

    my $range = sub {
      my ($val, $min, $max) = @_;
      return  $val < $min ? $min                          # Value below min
            : $val > $max ? $max                          # Value above max
                          : $val                          # Accept value
    };

    my $grow = sub {
      alias my $i = $_[0];
      if ( !( $self->grow_mode & GF_GROW_REL ) ) {
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
    $grow->($bounds->a->{x})                              # Grow left side
      if $self->grow_mode & GF_GROW_LO_X;
    $grow->($bounds->b->{x})                              # Grow right side
      if $self->grow_mode & GF_GROW_HI_X;
    if ( $bounds->b->x - $bounds->a->x > MAX_VIEW_WIDTH ) {
      $bounds->b->x( $bounds->a->x + MAX_VIEW_WIDTH )     # Check values
    }

    $s = $self->owner->size->y;                           # Set initial size
    $d = $delta->y;                                       # Set initial delta
    $grow->($bounds->a->{y})                              # Grow top side
      if $self->grow_mode & GF_GROW_LO_Y;
    $grow->($bounds->b->{y})                              # Grow lower side
      if $self->grow_mode & GF_GROW_HI_Y;

    $self->size_limits($min, $max);                       # Check sizes
    $bounds->b->x(                                        # Set right side
      $bounds->a->x
      + $range->($bounds->b->x - $bounds->a->x, $min->x, $max->x)
    );
    $bounds->b->y(                                        # Set lower side
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
    $self->draw_view();                                   # Draw the view
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

  method clear_event($) {
    alias my $event = $_[-1];
    confess 'Invalid argument $event'
      if not is_TEvent $event;

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
        || [$command] ~~ $cur_command_set;                # Check command
  }

=item I<data_size>

  method Int data_size()

Used in conjunction with L</get_data> and L</set_data> to copy the views data to
and from a data record.

B<See>: L</get_data>, L</set_data>

=cut

  method data_size() {
    return 0;                                             # Transfer size
  }

=item I<disable_commands>

  method disable_commands(TCommandSet $commands)
  method disable_commands(ArrayRef[Int] $commands)

The parameter I<$commands> is a reference containing a set of commands, 
specified by their I<cmXXXX> constant values, to be disabled.

Calling I<disable_commands> causes these I<$commands> to become greyed out on
the menus and status line.

B<See>: L</enable_commands>

=cut

  method disable_commands(TCommandSet|ArrayRef[Int] $commands) {
    $command_set_changed ||=                              # Set changed flag
      $cur_command_set * $commands != [];
    $cur_command_set = $cur_command_set - $commands;      # Update command set
    return;
  }

=item I<drag_view>

  method drag_view(TEvent $event, Int $mode, TRect $limits, TPoint $min_size, 
    TPoint $max_size)

The method I<drag_view> handles redrawing the view while it is being dragged 
across the string.

The parameter I<$limits> defines the rectangle in which the view can be dragged,
and I<$min_size> and I<$max_size> set the minimum and maximum sizes to which the
view can be resized.

=cut

  method drag_view(TEvent $event, Int $mode, TRect $limits, TPoint $min_size,
                   TPoint $max_size)
  {
    my ($p, $s) = ( TPoint->new, TPoint->new );
    my $save_bounds;

    my $move_grow = sub {
      my ( $p, $s ) = @_;

      $s->x( min( max( $s->x, $min_size->x ), $max_size->x ) );
      $s->y( min( max( $s->y, $min_size->y ), $max_size->y ) );

      $p->x( min( max( $p->x, $limits->a->x - $s->x + 1 ), $limits->b->x - 1 ) );
      $p->y( min( max( $p->y, $limits->a->y - $s->y + 1 ), $limits->b->y - 1 ) );

      $p->x( max( $p->x, $limits->a->x ) )
        if $mode & DM_LIMIT_LO_X;

      $p->y( max( $p->y, $limits->a->y ) )
        if $mode & DM_LIMIT_LO_Y;

      $p->x( min( $p->x, $limits->b->x - $s->x ) )
        if $mode & DM_LIMIT_HI_X;

      $p->y( min( $p->y, $limits->b->y - $s->y ) )
        if $mode & DM_LIMIT_HI_Y;

      my $r = TRect->init( $p->x, $p->y, $p->x + $s->x, $p->y + $s->y );
      $self->locate($r);
    };
    
    my $change = sub {
      my ( $dx, $dy ) = @_;
      if ( ( $mode & DM_DRAG_MOVE ) && !( get_shift_state & 0x03 ) ) {
        $p->x( $p->x + $dx );
        $p->y( $p->y + $dy );
      }
      elsif ( ( $mode & DM_DRAG_MOVE ) && ( get_shift_state & 0x03 ) ) {
        $s->x( $s->x + $dx );
        $s->y( $s->y + $dy );
      }
    };

    my $update = sub {
      my ($x, $y) = @_;
      if ( $mode & DM_DRAG_MOVE ) {
        $p->x($x);
        $p->y($y);
      }
    };

    $self->set_state(SF_DRAGGING, TRUE);
    if ( $event->what == EV_MOUSE_DOWN ) {
      if ( $mode & DM_DRAG_MOVE ) {
        $p = $self->origin - $event->where;
        do {
          $event->where += $p;
          $move_grow->($event->where, $self->size);
        } while ( $self->mouse_event($event, EV_MOUSE_MOVE) );
      }
      elsif ( $mode & DM_DRAG_GROW ) {
        $p = $self->size - $event->where;
        do {
          $event->where += $p;
          $move_grow->($self->origin, $event->where);
        } while ( $self->mouse_event($event, EV_MOUSE_MOVE) );
      }
      else {
        my $bounds = $self->get_bounds;
        $s->copy($self->origin);
        $s->y( $s->y + $self->size->y );
        $p = $s - $event->where;
        do {
          $event->where += $p;
          $bounds->a->x(
            min(
              max( $event->where->x, $bounds->b->x - $max_size->x ),
              $bounds->b->x - $min_size->x
            )
          );
          $bounds->b->y( $event->where->y );
          $move_grow->($bounds->a, $bounds->b - $bounds->a);
        } while( $self->mouse_event($event, EV_MOUSE_MOVE) );
      }
    }
    else {
      $self->get_bounds($save_bounds);
      do {
        $p->copy($self->origin);
        $s->copy($self->size);
        $self->key_event($event);
        SWITCH: for ( $event->key_code & 0xff00 ) {
          $_ == KB_LEFT       and $change->( -1,  0 );
          $_ == KB_RIGHT      and $change->(  1,  0 );
          $_ == KB_UP         and $change->(  0, -1 );
          $_ == KB_DOWN       and $change->(  0,  1 );
          $_ == KB_CTRL_LEFT  and $change->( -8,  0 );
          $_ == KB_CTRL_RIGHT and $change->(  8,  0 );
          $_ == KB_HOME       and $update->( $limits->a->x,         $p->y );
          $_ == KB_END        and $update->( $limits->b->x - $s->x, $p->y );
          $_ == KB_PG_UP      and $update->( $p->x, $limits->a->y );
          $_ == KB_PG_DN      and $update->( $p->x, $limits->b->y - $s->y );
        } #/ SWITCH: for ( $event->key_code ...)
        $self->move_grow($p, $s);
      } while ( $event->key_code != KB_ESC 
             && $event->key_code != KB_ENTER );
      $self->locate($save_bounds)
        if $event->key_code == KB_ESC;
    }
    $self->set_state(SF_DRAGGING, FALSE);
    
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

B<See>: L</draw_view>, L</get_clip_rect>

=cut

  method draw() {
    my $b = [];
    move_char($b, ' ', $self->get_color(1), $self->size->x);
    $self->write_line(0, 0, $self->size->x, $self->size->y, $b);
    return;
  }

=item I<draw_view>

  method draw_view()

The method I<draw_view> is the preferred method to call when you need to update 
the view.

That's because I<draw_view> makes a check to determine if the view is exposed
(not hidden behind another view) before attempting to call L</draw>.

The method L</draw> doesn't care if the view is visible since Turbo Vision will 
automatically clip away text that doesn't currently appear in a view.

B<See>: L</draw>

=cut

  method draw_view() {
    if ( $self->exposed ) {
      Video->lock_screen_update();    # don't update the screen yet
      $self->draw();
      Video->unlock_screen_update();
      $self->_do_refresh(FALSE);
      $self->_draw_cursor();
    }
    return;
  }

=item I<enable_commands>

  method enable_commands(TCommandSet $commands)
  method enable_commands(ArrayRef[Int] $commands)

The parameter I<$commands> is a reference containing a set of commands, 
specified by their I<cmXXXX> constant values, to be enabled.

The method I<enable_commands> is the inverse of L</disable_commands> and 
restores commands to an operable state.

=cut

  method enable_commands(TCommandSet|ArrayRef[Int] $commands) {
    $command_set_changed ||=                              # Set changed flag
      $cur_command_set * $commands != [];
    $cur_command_set = $cur_command_set + $commands;      # Update command set
    return;
  }

=item I<end_modal>

  method end_modal(Int $command)

Used internally in conjunction with I<exec_view> for displaying modal views,
such as dialogs, to terminate the modal view.

B<See:> I<< TGroup->end_modal >>, I<< TGroup->execute >>, 
I<< TGroup->exec_view >>

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

The method I<execute> is overridden in I<TGroup> descendants to provide the 
event loop that makes the view a modal view.

B<See>: I<< TGroup->end_modal >>, I<< TGroup->execute >>, 
I<< TGroup->exec_view >>

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
    return FALSE
        if !( $self->state & SF_EXPOSED )
        || $self->size->x <= 0
        || $self->size->y <= 0
        ;
    for ( my $y = 0; $y < $self->size->y; $y++ ) {
      $_static_var2->{y} = $y;
      return TRUE
          if $self->_exposed_rec2(0, $self->size->x, $self);
    }
    return FALSE;
  }

=item I<get_bounds>

  method focus() : Bool

Selects and focuses the view, returning True if the view owner returns True and
the view is neither selected nor modal, or if the view has no owner. Otherwise,
False is returned.

The difference between Focus and Select is that Focus can fail.

=cut

  method focus() {
    my $result = TRUE;                                    # Preset result

    if ( !( $self->state & (SF_SELECTED | SF_MODAL) ) ) { # Not modal/selected
      if ( my $owner = $self->owner ) {                   # View has an owner
        $result = $owner->focus;                          # Return focus state
        if ( $result ) {                                  # Owner has focus
          if ( !$owner->current                           # No current view
            || !( $owner->current->options & OF_VALIDATE )# Non validating view
            || $owner->current->valid(CM_RELEASED_FOCUS)  # Okay to drop focus
          ) { 
            $self->select();                              # Then select us
          } 
          else {
            $result = FALSE;
          }
        }
      }
    }
    return $result;                                       # Return focus result
  }

=item I<get_bounds>

  method get_bounds()

Returns the upper left and lower right corners of this view in I<$bounds>,
relative to the owner of the view.

=cut

  method get_bounds($) {
    alias my $bounds = $_[-1];
    confess 'Invalid argument $bounds'
      if not is_TRect $bounds;

    $bounds->a( $self->origin );                          # Get first corner
    $bounds->b( $self->origin + $self->size );            # Calc corner value
    return;
  }

=item I<get_clip_rect>

  method get_clip_rect(TRect $clip)

Returns the upper left and lower right corners in I<$clip> of the minimum
sized area that needs to be redrawn.

Uses this procedure in L</draw> to help locate only the area on the screen that
needs to be updated.

B<See>: L</draw>

=cut

  method get_clip_rect($) {
    alias my $clip = $_[-1];
    confess 'Invalid argument $clip'
      if not is_TRect $clip;

    $self->get_bounds($clip);                             # Get current bounds
    $clip->intersect($self->owner->_clip)                 # Intersect with owner
      if $self->owner;
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
    assert ( $color >> 16 == 0 );
    my $color_pair = $color >> 8;

    $color_pair = $self->map_color( $color_pair ) << 8
      if $color_pair;

    $color_pair |= $self->map_color( $color & 0xff );

    return $color_pair;
  }

=item I<get_commands>

  method get_commands(TCommandSet $commands)

Use I<get_commands> to fetch a set containing all of the currently enabled
commands.

=cut

  method get_commands($) {
    alias my $commands = $_[-1];
    confess 'Invalid argument $commands'
      if not is_TCommandSet $commands;

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
    confess 'Invalid argument $rec'
      if not is_Str $rec;

    return;                                               # Abstract method
  }

=item I<get_event>

  method get_event(TEvent $event)

Returns the next event from the event queue (typically called after calling
L</event_avail>).

=cut

  method get_event($) {
    alias my $event = $_[-1];
    confess 'Invalid argument $event'
      if not is_TEvent $event;

    $self->owner->get_event($event)                       # Event from owner
      if $self->owner;
    return;
  }

=item I<get_extent>

  method get_extent(TRect $extent)

Similar to L</get_bounds>, except that I<get_extent> sets I<< $extent->a >> =
(0,0) such that I<< $extent->b >>, which is set to L</size>, reflects the total
extent of the view relative to the upper left corner.

=cut

  method get_extent($) {
    alias my $extent = $_[-1];
    confess 'Invalid argument $extent'
      if not is_TRect $extent;

    $extent->a->x(0);                                     # Zero x field
    $extent->a->y(0);                                     # Zero y field
    $extent->b( $self->size );                            # Return size
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

  method get_peer_view_ptr(TStream $s, Ref $p)

Used by L</load> when certain objects need to load a peer view, I<$p>, from
stream I<$s>, such as a list box needing to load it scroll bar object.

=cut

  method get_peer_view_ptr(TStream $s, $p) {
    alias my $p = $_[-1];
    confess 'Invalid argument $p'
      if not is_Ref $p;
    
    my $read = sub {
      my $type = shift;
      if ( $type =~ /integer/ ) {
        $s->read(my $buf, integer->size);
        return integer( $buf )->unpack;
      };
      return undef;
    };

    my $index = 'integer'->$read();                       # Read view index
    $index //= 0;                                         # Zero index value
    if ( $index == 0 || !defined($_owner_group) ) {       # Check for peer views
      $p = undef;                                         # Return undef
    }
    else {
      carp "Unsafe: 'get_peer_view_ptr' must be adapted to perl suitable";
      $p = $_fixup_list->[$index];                        # New view reference
      $_fixup_list->[$index] = \$p;                       # Patch this reference
    }
    return;
  }

=item I<get_state>

  method get_state(Int $a_state) : Bool

Parameter I<$a_state> can be set to multiple combinations of the I<sfXXXX>
constants and returns True if the the indicated bits are set in the L</state>
variable.

B<See>: L</state>, I<sfXXXX> constants

=cut

  method get_state(Int $a_state) {
    return ($self->state & $a_state) == $a_state;         # Check states equal
  }

=item I<grow_to>

  method grow_to(Int $x, Int $y)

Calls L</locate> to adjust the size of the view.

=cut

  method grow_to(Int $x, Int $y) {
    my $r = TRect->init(                                  # Assign area
      $self->origin->x,
      $self->origin->y,
      $self->origin->x + $x,
      $self->origin->y + $y
    );
    $self->locate($r);                                    # Locate the view
    return;
  }

=item I<handle_event>

  method handle_event(TEvent $event)

Every view must override the I<handle_event> method.

This is where events are recognized and parceled out to make the view come
alive.

For an example, see I<TVSHELL8.PAS>, I<< TShell.HandleEvent >>, in the Borland
Pascal Developer's Guide.

B<See>: I<evXXXX> constants, I<cmXXXX> constants
     
=cut

  method handle_event($) {
    alias my $event = $_[-1];
    confess 'Invalid argument $event'
      if not is_TEvent $event;

    if ( $event->what == EV_MOUSE_DOWN ) {                # Mouse down event
      if ( !($self->state & (SF_SELECTED | SF_DISABLED))  # Not select/disabled
        && ($self->options & OF_SELECTABLE)               # View is selectable
      ) {
        if ( !$self->focus                                # Not view with focus
          || !($self->options & OF_FIRST_CLICK)           # Not 1st click select
        ) {
          $self->clear_event($event)                      # Handle the event
        }
      }
    }
    return;
  }

=item I<hide>

  method hide()

Hides the view.

B<See>: L</show>

=cut

  method hide() {
    $self->set_state(SF_VISIBLE, FALSE)                   # Hide the view
      if $self->state & SF_VISIBLE;                       # View is visible
    return;
  }

=item I<hide_cursor>

  method hide_cursor()

Hides the cursor.

B<See>: L</show_cursor>

=cut

  method hide_cursor() {
    $self->set_state(SF_CURSOR_VIS, FALSE);              # Hide the cursor
    return;
  }

=item I<key_event>

  method key_event(TEvent $event)

I<key_event> ignores all incoming events until it gets an I<EV_KEY_DOWN> event,
and it returns that event.

=cut

  method key_event($) {
    alias my $event = $_[-1];
    confess 'Invalid argument $event'
      if not is_TEvent $event;

    do {
      $self->get_event($event);                           # Get next event
    } while ( $event->what != EV_KEY_DOWN );              # Wait till keydown
    return;
  }

=item I<locate>

  method locate(TRect $bounds)

Changes the boundaries of the view and redisplays the view on the screen.

=cut

  method locate($) {
    alias my $bounds = $_[-1];
    confess 'Invalid argument $bounds'
      if not is_TRect $bounds;

    my $range = sub {
      my ($val, $min, $max) = @_;
      return  $val < $min ? $min                          # Value below min
            : $val > $max ? $max                          # Value above max
                          : $val                          # Accept value
    };

    my ($min, $max) = ( TPoint->new, TPoint->new );
    $self->size_limits($min, $max);                       # Get size limits
    $bounds->b->x(                                        # X bound limit
      $bounds->a->x
      + $range->( $bounds->b->x - $bounds->a->x, $min->x, $max->x )
    );
    $bounds->b->y(                                        # Y bound limit
      $bounds->a->y
      + $range->( $bounds->b->y - $bounds->a->y, $min->y, $max->y )
    );
    my $r = TRect->new();
    $self->get_bounds($r);                                # Current bounds
    if ( $bounds != $r ) {                                # Size has changed
      $self->change_bounds($bounds);                      # Change bounds
      if ( $self->state & SF_VISIBLE                      # View is visible
        && $self->state & SF_EXPOSED                      # Check view expose
        && $self->owner
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
      if $self->owner;                                    # Must have owner
    return;
  }

=item I<make_global>

  method make_global(TPoint $source, TPoint $dest)

Use I<make_global> (see also L</make_local>) to convert I<$source>, which
contains view relative coordinates, to screen coordinates.

The converted value is returned in I<$dest>.

=cut

  method make_global(TPoint $source, $) {
    # Note: $source and $dest can be the same variable
    alias my $dest = $_[-1];
    confess 'Invalid argument $dest'
      if not is_TPoint $dest;

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

B<See>: L</make_global>.

=cut

  method make_local(TPoint $source, $) {
    # Note: $source and $dest can be the same variable
    alias my $dest = $_[-1];
    confess 'Invalid argument $dest'
      if not is_TPoint $dest;

    my $cur = $self;
    $dest->copy($source);
    do {
      $dest->x( $dest->x - $cur->origin->x );
      return
        if $dest->x < 0;
      $dest->y( $dest->y - $cur->origin->y );
      return
        if $dest->y < 0;
      $cur = $cur->owner;
    } while ( defined $cur );
    return;
  }

=item I<map_color>

  method map_color(Int $color) : Int

Convert color into attribute.

=cut

  method map_color(Int $color) {
    assert ( $color >> 16 == 0 );
    return $error_attr
        if $color == 0;
    my $cur = $self;
    do {
      my $p = $cur->get_palette();                        # Get our palette
      if ( defined $p ) {                                 # Palette is valid
        return $error_attr                                # Error attribute
            if $color > length($p);
        $color = unpack('x'.$color.'C', $p);              # Return colour
        return $error_attr                                # Error attribute
            if not $color;
      }
      $cur = $cur->owner;
    } while ( defined $cur );
    return $color;
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

  method mouse_event($, Int $mask) {
    alias my $event = $_[-2];
    confess 'Invalid argument $event'
      if not is_TEvent $event;

    do {
      $self->get_event($event);                           # Get next event
    } while ( !($event->what & ($mask | EV_MOUSE_UP)) );  # Wait till valid
    return $event->what != EV_MOUSE_UP;                   # Return result
  }

=item I<mouse_in_view>

  method mouse_in_view(TPoint $mouse) : Bool

If the point described by I<$mouse> (in screen coordinates) lies within this
view, then I<mouse_in_view> returns True.

=cut

  method mouse_in_view(TPoint $mouse) {
    $self->make_local($mouse, $mouse);
    return $mouse->x >= 0
        && $mouse->y >= 0
        && $mouse->x < $self->size->x
        && $mouse->y < $self->size->y;
  }

=item I<move_to>

  method move_to(Int $x, Int $y)

Keeping the view the same size, I<move_to> moves the upper left corner, and
hence the entire view, to the new point I<($x,$y)>.

=cut

  method move_to(Int $x, Int $y) {
    my $r = TRect->init(                                  # Assign area
      $x, $y,
      $x + $self->size->x,
      $y + $self->size->y
    );
    $self->locate($r);                                    # Locate the view
    return;
  }

=item I<next_view>

  method next_view() : TView|Undef

I<next_view> returns a Reference to the next view, in sequence, in the owner's
list of views, or C<undef> if it has reached the end of the list.

=cut

  method next_view() {
    return undef
        if $self->owner && $self == $self->owner->last;   # This is last view
    return $self->next;                                   # Return our next
  }

=item I<normal_cursor>

  method normal_cursor()

Sets the screen cursor to an underscore-style cursor.

B<See>: L</block_cursor>.

=cut

  method normal_cursor() {
    $self->set_state(SF_CURSOR_INS, FALSE);
    return;
  }

=item I<prev>

  method prev() : TView

I<prev> returns a reference to the previous view, in sequence, in the owner's
list of views, and cycles back to the beginning of the list if it has reached
the end.

=cut

  method prev() {
    my $res = $self;
    while( $res && $res->next != $self ) {
      $res = $res->next;
    }
    return $res;
  }

=item I<prev_view>

  method prev_view() : TView|Undef

Identical to L</prev> except that if I<prev_view> reaches the beginning of
the view list, I<prev_view> returns C<undef>.

=cut

  method prev_view() {
    return undef
      if $self->owner && $self == $self->owner->first;    # This is first view
    return $self->prev;                                   # Return our prev
  }

=item I<put_event>

  method put_event(TEvent $event)

Using I<put_event>, you can force one and only one event to be inserted as the
next event in the event queue.

I<$event> will become the next event retrieved by L</get_event>.

=cut

  method put_event(TEvent $event) {
    $self->owner->put_event($event)                       # Put in owner
      if $self->owner;
    return;
  }

=item I<put_in_front_of>

  method put_in_front_of(TView|Undef $target)

Where I<$target> is any view in this view's owner's view list,
I<put_in_front_of> moves this view to be placed directly in front of I<$target>.

=cut

  method put_in_front_of(TView|Undef $target) {
    assert ( exists $$self{state} );
    alias my $state = $self->{state};
          my $owner = $self->owner;

    if ( $owner                                           # Check validity
      && $target != $self
      && $target != $self->next_view()
      && (!defined($target) || $target->owner == $owner)
    ) {
      if ( not $self->state & SF_VISIBLE ) {              # View not visible
        $owner->remove_view($self);                       # Remove from list
        $owner->insert_view($self, $target);              # Insert into list
      }
      else {
        my $last_view = $self->next_view();               # Hold next view
        if ( $last_view ) {                               # Last view is valid
          my $p = $target;                                # $p is target
          while ( $p && $p != $last_view ) {
            $p = $p->next_view();                         # Find our next view
          }
          $last_view = $target                            # Last view is target
            if not defined $p
        }
        $state &= ~SF_VISIBLE;                            # Temp stop drawing
        $self->_draw_hide($last_view)
          if $last_view == $target;
        $owner->lock();
        $owner->remove_view($self);                       # Remove from list
        $owner->insert_view($self, $target);              # Insert into list
        $state |= SF_VISIBLE;                             # Allow drawing again
        $self->_draw_show($last_view)
          if $last_view != $target;
        if( $self->options & OF_SELECTABLE ) {            # View is selectable
          $owner->_reset_current();                       # Reset current
          $owner->_reset_cursor();
        }
        $owner->unlock();
      }
    }
    return;
  }

=item I<put_peer_view_ptr>

  method put_peer_view_ptr(TStream $s, TView|Undef $r)

The L</store> method calls this routine to write the "peer" view object I<$r>
to stream I<$s>.

=cut

  method put_peer_view_ptr(TStream $s, TView|Undef $p) {
    my $write = sub {
      my $type = shift;
      my $value = shift // 0;
      if ( $type =~ /integer/ ) {
        $s->write( integer($value)->pack, integer->size );
      }
    };

    my $index = 0;                                        # Return zero index
    if ( $p && $_owner_group ) {
      $index = $_owner_group->index_of($p);               # Return view index
    }
    'integer'->$write( $index );                          # Write the index
    return;
  }

=item I<select>

  method select()

I<select> makes this view the active view in the group, and if the owning group
is on the focused chain, then this view becomes the focused view.

=cut

  method select() {
    if ( $self->options & OF_SELECTABLE ) {               # View is selectable
      if ( $self->options & OF_TOP_SELECT ) {             # Top selectable
        $self->make_first
      }
      elsif ( $self->owner ) {                            # Valid owner
                                                          # Make owners current
        $self->owner->set_current($self, $self->normal_select);
      }
    }
    return;
  }

=item I<set_bounds>

  method set_bounds(TRect $bounds)

This is an internal routine called by L</change_bounds>.

=cut

  method set_bounds(TRect $bounds) {
    $self->origin->copy( $bounds->a );                    # Get first corner
    $self->size->copy( $bounds->b - $bounds->a );         # Get second corner
    return;
  }

=item I<set_cmd_state>

  method set_cmd_state(TCommandSet $commands, Bool $enable)
  method set_cmd_state(ArrayRef[Int] $commands, Bool $enable)

Depending on I<$enable> the current list of commands is expanded
(I<$enable> = true) or reduced (I<$enable> = false) to the set passed in the
parameter I<$commands>.

B<See>: L</enable_commands>, L</disable_commands>

=cut

  method set_cmd_state(TCommandSet|ArrayRef[Int] $commands, Bool $enable) {
    if ( $enable ) {
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

B<See>: L</enable_commands>, L</disable_commands>

=cut

  method set_commands(TCommandSet $commands) {
    $command_set_changed ||=
      $cur_command_set != $commands;                      # Set change flag
    $cur_command_set->copy($commands);                    # Set command set
    return;
  }

=item I<set_cursor>

  method set_cursor(Int $x, Int $y)

Moves the screen cursor to I<($x,$y)> where I<$x> and I<$y> are local
coordinates.

=cut

  method set_cursor(Int $x, Int $y) {
    if ( $self->cursor->x != $x && $self->cursor->y != $y ) {
      $self->cursor->x($x);
      $self->cursor->y($y);
      $self->_cursor_changed();
    }
    $self->_draw_cursor;
    return;
  }

=item I<set_data>

  method set_data(Str $rec)

Copies L</data_size> bytes from I<$rec> to the view's data fields.

B<See>: L</data_size>, L</get_data>

=cut

  method set_data(Str $rec) {
    return;                                               # Abstract method
  }

=item I<set_state>

  method set_state(Int $a_state, Bool $enable)

Use I<set_state> to either set or clear bits in the L</state> variable.

If I<$enable> is True, then the bits specified by I<$a_state> are set, and
if I<$enable> is False, then the bits specified by
I<$a_state> are cleared.

=cut

  method set_state(Int $a_state, Bool $enable) {
    my $state = $self->state;
    if ( $enable ) {
      $state |= $a_state
    }
    else {
      $state &= ~$a_state
    }
    $self->_state($state);

    my $owner = $self->owner;
    return
        if not $owner;
    
    SWITCH: for ( $a_state ) {
      $_ == SF_VISIBLE and do {
        $self->set_state(SF_EXPOSED, $enable)
          if $owner->state & SF_EXPOSED;
        if ( $enable ) {
          $self->_draw_show(undef)
        }
        else {
          $self->_draw_hide(undef)
        }
        $owner->reset_current
          if $self->options & OF_SELECTABLE;
        last;
      };
      $_ == SF_CURSOR_VIS
        ||
      $_ == SF_CURSOR_INS and do {
        $self->_draw_cursor;
        last;
      };
      $_ == SF_SHADOW and do {
        $self->_draw_under_view(TRUE, undef);
        last;
      };
      $_ == SF_FOCUSED and do {
        $self->_reset_cursor;
        my $command = $enable ? CM_RECEIVED_FOCUS 
                              : CM_RELEASED_FOCUS;
        if ( my $event = TEvent->new() ) {
          $event->what( EV_BROADCAST );                   # Set what
          $event->command( $command );                    # Set command
          $event->info_ptr( $self );                      # Set info ptr
          $owner->handle_event($event);                   # Pass to handler
        }
        last;
      };
    }
    $self->_cursor_changed()
      if ($state ^ $self->state) & (SF_CURSOR_VIS | SF_CURSOR_INS | SF_FOCUSED);
    return;
  }

=item I<show>

  method show()

Causes the view to be displayed.

B<See>: L</hide>

=cut

  method show() {
    $self->set_state(SF_VISIBLE, TRUE)                    # Show the view
      if not $self->state & SF_VISIBLE;                   # View not visible
    return;
  }

=item I<show_cursor>

  method show_cursor()

Makes the screen cursor visible (the default condition is a hidden cursor).

=cut

  method show_cursor() {
    $self->set_state(SF_CURSOR_VIS, TRUE);                # Show the cursor
    return;
  }

=item I<show_cursor>

  method size_limits(TPoint $min, TPoint $max)

Sets I<$min> to (0,0) and I<$max> to I<< $self->owner->size >>.

=cut

  method size_limits($, $) {
    alias my $min = $_[-2];
    alias my $max = $_[-1];
    confess 'Invalid argument $min'
      if not is_TPoint $min;
    confess 'Invalid argument $max'
      if not is_TPoint $max;

    $min->x(0);                                           # Zero x minimum
    $min->y(0);                                           # Zero y minimum
    if ( $self->owner ) {
      $max->copy($self->owner->size);
    }
    else {                                                # Max owner size
      $max->x(_INT16_MAX);                                # Max possible x size
      $max->y(_INT16_MAX);                                # Max possible y size
    }
    return;
  }

=item I<store>

  method store(TStream $s)

Writes I<$self> view to stream I<$s>.

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
    return $_the_top_view                                 # Return topview
        if $_the_top_view;                                # Check topmost view

    my $view = $self;                                     # Start with us
    while ( $view && !($view->state & SF_MODAL) ) {       # Check if modal
      $view = $view->owner;                               # Search each owner
    }
    return $view;                                         # Return result
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
    return TRUE;                                         # Simply return true
  }

=item I<write_buf>

  method write_buf(Int $x, Int $y, Int $w, Int $h, TVideoBuf $buf)

The mehtod I<write_buf> is called from with I<< TView->draw >> to copy the bytes 
from I<$buf> to the location on the view specified by the coordinates (I<$x,$y>) 
and extending over I<$w> characters and down I<$h> lines. The param I<$buf> is 
an ArrayRef of Int, with each Int containing both a character to output and its 
corresponding video memory color attribute (See I<TDrawBuffer>)

=cut

  method write_buf(Int $x, Int $y, Int $w, Int $h, TVideoBuf $buf) {
    assert ( $w >= 0 );
    if ( $h > 0 ) {
      for my $i ( 0 .. $h-1 ) {
        my $a = $w * $i;
        my $b = min($a + $w, $#$buf);
        my $draw_buffer = [ @$buf[ $a .. $b ] ];
        $self->_write_view($x, $x + $w, $y + $i, $draw_buffer);
      }
    }
    return;
  }

=item I<write_char>

  method write_char(Int $x, Int $y, Str $ch, Int $color, Int $count)

From within a I<< TView->draw >> method, I<write_char> copies the character 
I<$ch>, having the color index I<$color>, to the screen, starting at (I<$x,$y>) 
and continuing for I<$count> number of characters.

=cut

  method write_char(Int $x, Int $y, Str $ch, Int $color, Int $count) {
    if ( $count > 0 ) {
      my $cell = $self->map_color($color) << 8 + ord($ch);
      $count = min( $count, MAX_VIEW_WIDTH );
      my $draw_buffer = [ ( $cell ) x ( 0 .. $count-1 ) ];
      $self->_write_view($x, $x + $count, $y, $draw_buffer);
    }
    $self->_do_refresh(FALSE);
    return;
  }

=item I<write_line>

  method write_line(Int $x, Int $y, Int $w, Int $h, TDrawBuffer $buf)

From within a I<< TView->draw >> method, I<write_line> outputs I<$buf> (which is 
an ArrayRef of Int; see I<TDrawBuffer>), starting at the view's coordinates 
(I<$x,$y>), and copies I<$w> bytes from I<$buf>.  

B<Important>! I<$w> should be exactly equal to the number of characters to copy 
from I<$buf>.  If larger than the contents of the string represented in I<$buf>,
then I<write_line> will copy data beyond the end of I<$buf> and undef data will 
appear at those locations.  If I<$h> is more than C<1>, then I<write_line> 
displays the contents of I<$buf> on each of the succeeding lines.

=cut

  method write_line(Int $x, Int $y, Int $w, Int $h, TDrawBuffer $buf) {
    assert ( $w >= 0 );
    if ( $h > 0 ) {
      for my $i ( 0 .. $h-1 ) {
        $self->_write_view($x, $x + $w, $y + $i, $buf);
      }
    }
    $self->_do_refresh(FALSE);
    return;
  }

=item I<write_str>

  method write_str(Int $x, Int $y, Str $str, Int $color)

The method I<write_str> is probably the most commonly used method for performing 
output within L</draw> methods.  Use I<write_str> to output the string I<$str> 
to the screen, starting at (I<$x,$y>) and having the color index specified by 
I<$color>.

=cut

  method write_str(Int $x, Int $y, Str $str, Int $color) {
    my $len = length( $str );
    if ( $len > 0 ) {
      $len = min( $len, MAX_VIEW_WIDTH );
      my $attr = $self->map_color($color) << 8;
      my $draw_buffer =
        [ map { $attr + ord(substr($str, $_, 1)) } 0 .. $len-1 ];
      $self->_write_view($x, $x + $len, $y, $draw_buffer);
    }
    $self->_do_refresh(FALSE);
    return;
  }

=back

=cut

  # ------------------------------------------------------------------------
  # Private Methods --------------------------------------------------------
  # ------------------------------------------------------------------------

=begin comment

=head2 Private Methods

=over

=item I<_cursor_changed>

  method _cursor_changed()

Generates a broadcast notification that the cursor has been changed and puts it 
in the event queue. 

=cut

  method _cursor_changed() {
    if ( my $receiver = $self->owner ) {                  # Valid receiver
      if ( my $event = TEvent->new() ) {                  # Default fields
        $event->what( EV_BROADCAST );                     # Set what
        $event->command( CM_CURSOR_CHANGED );             # Set command
        $event->info_ptr( $self );                        # Set info ptr
        $receiver->handle_event($event);                  # Pass to handler
      }
    }
    return;
  }

=item I<_do_refresh>

  method _do_refresh(Bool $force)

This code is used to refresh the screen only if strictly necessary.

=cut

  method _do_refresh(Bool $force) {
    my $lock_refresh = Video->get_lock_screen_count() // -1;
    return                                                # do not update
        if $lock_refresh != 0;
    Video->update_screen($force);
    return;
  }

=item I<_draw_cursor>

  method _draw_cursor()

Resets the cursor if the status is C<SF_FOCUSED>.

B<See>: L</_reset_cursor>

=cut

  method _draw_cursor() {
    $self->_reset_cursor
      if $self->state & SF_FOCUSED;
    return;
  }

=item I<_draw_hide>

  method _draw_hide(TView|Undef $last_view)

Calls L</_draw_cursor> and then L</_draw_under_view> using the I<$last_view>.

=cut

  method _draw_hide(TView|Undef $last_view) {
    $self->_draw_cursor();
    $self->_draw_under_view(( $self->state & SF_SHADOW ) != 0, $last_view);
    return;
  }

=item I<_draw_show>

  method _draw_show(TView|Undef $last_view)

Calls L</draw_view> and if shadow also L</_draw_under_view>.

=cut

  method _draw_show(TView|Undef $last_view) {
    $self->draw_view();
    if ( $self->state & SF_SHADOW ) {
      $self->_draw_under_view(TRUE, $last_view);
    }
    return;
  }

=item I<_draw_under_rect>

  method _draw_under_rect(TRect $r, TView|Undef $last_view)

Draw under rectangle.

=cut

  method _draw_under_rect(TRect $r, TView|Undef $last_view) {
    my $owner = $self->owner;
    $owner->_clip->intersect($r);
    $owner->_draw_sub_views($self->next_view(), $last_view);
    $owner->get_extent($owner->_clip);
    return;
  }

=item I<_draw_under_view>

  method _draw_under_view(Bool $shadow, TView|Undef $last_view)

Draw under view.

B<See>: L</_draw_under_rect>

=cut

  method _draw_under_view(Bool $shadow, TView|Undef $last_view) {
    my $r = TRect->new();
    $self->get_bounds($r);
    if ( $shadow ) {
      $r->b->x( $r->b->x + $shadow_size->x );
      $r->b->y( $r->b->y + $shadow_size->y );
    }
    $self->_draw_under_rect($r, $last_view);
    return;
  }
  
=item I<_exposed_rec1>

  method _exposed_rec1(Int $x1, Int $x2, TView $p) : Bool

This method is a port of the assembler code of I<TVWRITE.ASM>.

The code base was originally written by Jörn Sierwald in C++ and ported now to 
Perl.

=cut

  method _exposed_rec1(Int $x1, Int $x2, TView $p) {
    while (1) {
      $p = $p->next;
      return $self->_exposed_rec2($x1, $x2, $p->owner)    # run completed
          if $p eq $_static_var2->{target};

      my $ax = $p->origin->y;
      my $bx = $p->origin->x;
      next                                                # no overlapping
        if !( $p->state & SF_VISIBLE ) 
        && $_static_var2->{y} < $ax;

      if ( $_static_var2->{y} < $ax + p->size->y ) {
        # overlapping possible
        if ( $x1 < $bx ) {                                # starts left of view
          next                                            # left complete
            if $x2 <= $bx;
          if ( $x2 > $bx + $p->size->x ) {
            return TRUE
                if $self->_exposed_rec1($x1, $bx, $p);
            $x1 = $bx + $p->size->x;
          }
          else {
            $x2 = $bx;
          }
        }
        else {
          $x1 = max( $x1, $bx + $p->size->x );
          return FALSE                                    # completely covered
              if $x1 >= $x2;
        }
      }
    } #/ while ( 1 )
  }

=item I<_exposed_rec2>

  method _exposed_rec2(Int $x1, Int $x2, TView $p) : Bool

This method is a port of the assembler code of I<TVWRITE.ASM>.

The code base was originally written by Jörn Sierwald in C++ and ported now to 
Perl.

=cut

  method _exposed_rec2(Int $x1, Int $x2, TView $p) {
    return FALSE
        if not $p->state & SF_VISIBLE;

    my $owner = $p->owner;
    return TRUE
        if !$owner || $owner->buffer;

    my $saved_statics = { %$_static_var2 };

    $_static_var2->{y} += $p->origin->y;
    $x1 += $p->origin->x;
    $x2 += $p->origin->x;
    $_static_var2->{target} = $p;

    my $exposed = FALSE;
    if ( $_static_var2->{y} >= $owner->_clip->a->y 
      && $_static_var2->{y} <  $owner->_clip->b->y 
    ) {
      $x1 = max( $x1, $owner->_clip->a->x );
      $x2 = min( $x2, $owner->_clip->b->x );
      if ( $x1 < $x2 ) {
        $exposed = $self->_exposed_rec1($x1, $x2, $owner->last);
      }
    }

    $_static_var2 = { %$saved_statics };
    return $exposed;
  }

=item I<_reset_cursor>

  method _reset_cursor()

I<TView> member function.

This method is a port of the assembler code of I<TVWRITE.ASM>.

The code base was originally written by Jörn Sierwald in C++ and ported now to 
Perl.

=cut

  method _reset_cursor() {
    use constant _SF_VCVF => SF_VISIBLE | SF_CURSOR_VIS | SF_FOCUSED;

    my ($p, $p2);
    my $cur = TPoint->new;
  
    if ( ( $self->state & _SF_VCVF ) == _SF_VCVF ) {
      $p = $self;
      $cur->copy($self->cursor);
      while (1) {
        last
          if $cur->x < 0
          || $cur->x >= $p->size->x
          || $cur->y < 0
          || $cur->y >= $p->size->y
          ;
        $cur += $p->origin;
        $p2 = $p;
        my $owner = $p->owner;
        if ( not defined $owner ) {                       # top view
          Video->set_cursor_pos($cur->x, $cur->y);        # set cursor
          # we should change the cursor size according to 
          # the SF_CURSOR_INS flag in the state variable
          Video->set_cursor_type(
            $self->state & SF_CURSOR_INS
              ? CR_BLOCK
              : CR_UNDER_LINE
          );
          return;
        }
        last
          if not $owner->state & SF_VISIBLE;

        $p = $owner->last;
        my $res = 0;
        while ( $res == 0 ) {
          $p = $p->next;
          if ( $p == $p2 ) {
            $p = $p->owner;
            $res = 1;                                     # run completed
          }
          elsif ( $p->state & SF_VISIBLE
            && $cur->x >= $p->origin->x
            && $cur->x < $p->size->x + $p->origin->x
            && $cur->y >= $p->origin->y
            && $cur->y < $p->size->y + $p->origin->y
          ) {
            $res = 2;                                     # cursor is covered
          }
        } #/ while ( $res == 0 )
        last 
          if $res == 2;
      } #/ while ( 1 )
    }
    Video->set_cursor_type(CR_HIDDEN);                    # no cursor, please.
    return;
  }

=item I<_write_view>

  method _write_view(Int $x1, Int $x2, Int $y, TDrawBuffer $buf)

This method is a port of the assembler code of I<TVWRITE.ASM>.

The code base was originally written by Jörn Sierwald in C++ and ported now to 
Perl.

=cut

  method _write_view(Int $x1, Int $x2, Int $y, TDrawBuffer $buf) {
    if ( $y >= 0 && $y < $self->size->y ) {
      $x1 = max( $x1, 0 );
      $x2 = min( $x2, $self->size->x );
      if ( $x1 < $x2 ) {
        $_static_var2->{offset} = $x1;
        $_static_var2->{y} = $y;
        $_static_var1 = $buf;
        $self->_write_view_rec2( $x1, $x2, $self, 0 );
      }
    }
    return;
  }

=item I<_write_view_rec1>

  method _write_view_rec1(Int $x1, Int $x2, TView $p, Int $shadow_counter)

This method is a port of the assembler code of I<TVWRITE.ASM>.

The code base was originally written by Jörn Sierwald in C++ and ported now to 
Perl.

=cut

  method _write_view_rec1(Int $x1, Int $x2, TView $p, Int $shadow_counter) {
    while (1) {
      $p = $p->next;
      if ( $p eq $_static_var2->{target} ) {              # run completed
        # print it!
        my $owner = $p->owner;
        if ( defined $owner->buffer ) {
          my $n = $x2 - $x1;
          my $dst = $owner->size->x * $_static_var2->{y} + $x1;
          my $src = $x1 - $_static_var2->{offset};

          if ( $shadow_counter == 0 ) {
            # writes a row of data to the screen
            splice(
              @{ $owner->buffer }, $dst, $n,
              $_static_var1->[ $src .. $n ]
            );
          }
          else {                                          # paint shadow attr
            while ( $n-- ) {
				      my $cell = ( $_static_var1->[ $src++ ] & 0xff ) 
                       | ( $shadow_attr << 8 );
              # writes a character on the screen
              $owner->buffer->[$dst++] = $cell;
            }
          } #/ else [ if ( $shadow_counter ...)]
        } #/ if ( defined $owner->buffer )
        $self->_write_view_rec2($x1, $x2, $owner, $shadow_counter)
          if not $owner->_lock_flag;
        return;
      } #/ if ( $p eq $_static_var2...)

      next                                                # no overlapping
        if !( $p->state & SF_VISIBLE )
        || $_static_var2->{y} < $p->origin->y;


      # overlapping possible      
      if ( $_static_var2->{y} < $p->origin->y + $p->size->y ) {
        if ( $x1 < $p->origin->x ) {                      # starts left of view
          next                                            # left complete
            if $x2 <= $p->origin->x;
          $self->_write_view_rec1(
            $x1, $p->origin->x, $p, $shadow_counter
          );
          $x1 = $p->origin->x;
        }
        my $bx = $p->origin->x + $p->size->x;

        return                                            # completely covered
            if $x2 <= $bx;

        $x1 = max( $x1, $bx );
        $bx += $shadow_size->x;

        # could possibly be in the shade
        next                                              # 1st row has no shade
          if !( $p->state & SF_SHADOW )
          || $_static_var2->{y} < $p->origin->y + $shadow_size->y;
        next                                              # right complete
          if $x1 >= $bx;
        $shadow_counter++;
        next                                              # all in the shade
          if $x2 <= $bx;

        # split shadow part, right next to it
        $self->_write_view_rec1($x1, $bx, $p, $shadow_counter);
        $x1 = $bx;
        $shadow_counter--;
        next;
      } 
      next                                              # too far down
        if !( $p->state & SF_SHADOW )
        || $_static_var2->{y} >= $p->origin->y + $p->size->y + $shadow_size->y;
      my $bx = $p->origin->x + $shadow_size->x;         # in the y-shadow?
      if ( $x1 < $bx ) {
        next                                            # left complete
          if $x2 <= $bx;
        $self->_write_view_rec1($x1, $bx, $p, $shadow_counter);
        $x1 = $bx;
      }
      $bx += $p->size->x;
      next 
        if $x1 >= $bx;
      $shadow_counter++;
      next                                              # all in the shade
        if $x2 <= $bx;

      # split shadow part, right next to it
      $self->_write_view_rec1($x1, $bx, $p, $shadow_counter);
      $x1 = $bx;
      $shadow_counter--;
    } #/ while ( 1 )
  } #/ sub _write_view_rec1

=item I<_write_view_rec2>

  method _write_view_rec2(Int $x1, Int $x2, TView $p, Int $shadow_counter)

This method is a port of the assembler code of I<TVWRITE.ASM>.

The code base was originally written by Jörn Sierwald in C++ and ported now to 
Perl.

=cut

  method _write_view_rec2(Int $x1, Int $x2, TView $p, Int $shadow_counter) {
    my $owner = $p->owner;
    return 
        if !( $p->state & SF_VISIBLE ) 
        || !$owner;

    my $saved_statics = { %$_static_var2 };

    $_static_var2->{y}      += $p->origin->y;
    $x1                     += $p->origin->x;
    $x2                     += $p->origin->x;
    $_static_var2->{offset} += $p->origin->x;
    $_static_var2->{target} = $p;

    if ( $_static_var2->{y} <  $owner->_clip->a->y
      || $_static_var2->{y} >= $owner->_clip->b->y 
    ) {
      $_static_var2 = { %$saved_statics };
      return;
    }
    $x1 = max( $x1, $owner->_clip->a->x );
    $x2 = min( $x2, $owner->_clip->b->x );
    if ( $x1 >= $x2 ) {
      $_static_var2 = { %$saved_statics };
      return;
    }

    $self->_write_view_rec1($x1, $x2, $owner->last, $shadow_counter);
    $_static_var2 = { %$saved_statics };
    return;
  } #/ sub _write_view_rec2

=back

=end comment

=cut

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

1993-1994 by Jörn Sierwald (some code based on the C++ Version of TVWRITE.ASM)

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

2023-2024 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

I<TObject>, 
L<views.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/views.pas>, 
L<asm.cc|https://github.com/kloczek/tvision/blob/master/tvision/asm.cc>
