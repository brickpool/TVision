=pod

=head1 NAME

TView - buffer used by draw methods

=head1 SYNOPSIS

  use TurboVision::Views;
  
  my $buf = TView->new();
  ...

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

use TurboVision::Const qw( :bool );
# Objects
use TurboVision::Objects::Types qw(
  TObject
  TPoint
  TRect
  TStream
  TStreamRec
);
use TurboVision::Objects::Point;
use TurboVision::Objects::Rect;
use TurboVision::Objects::Stream;
use TurboVision::Objects::StreamRec;
# Drivers
use TurboVision::Drivers::Const qw(
  :evXXXX
  :kbXXXX
);
use TurboVision::Drivers::Types qw(
  TEvent
);
use TurboVision::Drivers::Event;
use TurboVision::Drivers::Utility qw(
  :move
);
use TurboVision::Drivers::Win32::Keyboard qw(
  :kbd
);
# Views
use TurboVision::Views::Common qw(
  :vars
);
use TurboVision::Views::Const qw(
  MAX_VIEW_WIDTH
  :cmXXXX
  :dmXXXX
  :gfXXXX
  :hcXXXX
  :sfXXXX
);
use TurboVision::Views::Types qw(
  TView
  TGroup
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

I<grow_mode>, I<drag_mode>, I<help_ctx>, I<state>, I<options> and I<event_mask>.

Commonly used methods include I<block_cursor>, I<clear_event>,
I<command_enabled>, I<data_size>, I<disable_commands>, I<draw>, I<draw_view>,
I<enable_commands>, I<get_color>, I<get_commands>, I<get_help_ctx>,
I<get_palette>, I<get_state>, I<hide_cursor>, I<normal_cursor>, I<select>,
I<set_commands>, I<set_state>, I<show>, I<show_cursor>, I<valid>, I<write_line>
and I<write_str>.

=head2 Class

public class C<< TView >>

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

=item public constant C<< Object RView >>

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

=item private C<< HashRef $static_var2 >>

Helper variable for I<TView> methods I<exposed> and I<write_str>.

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

=item public readonly C<< TPoint cursor >>

Records the position of the display cursor.

=cut

  has 'cursor' => (
    isa       => TPoint,
    default   => sub { TPoint->new() },
    writer    => '_cursor',
  );

=item public C<< Int drag_mode >>

The bits in I<drag_mode> indicate the view's dragging characterisitcs when
dragged with the mouse.

You must directly set a value to I<drag_mode> using the I<dmXXXX> constants.

See: I<dmXXXX> constants for more information on these settings.

=cut

  has 'drag_mode' => (
    is        => 'rw',
    isa       => Int,
    required  => 1,
  );

=item public C<< Int event_mask >>

Set I<event_mask> to mask off or on the classes of messages that are accepted
for processing by this view.

A value of C<0xffff> means that the view will accept all messages. 

You set I<event_mask>to a combination of the I<evXXXX> constants.

See: I<evXXXX> constants

=cut

  has 'event_mask' => (
    is        => 'rw',
    isa       => Int,
    required  => 1,
  );

=item public C<< Int grow_mode >>

The bit settings in I<grow_mode> indicate how the view will change shape when
it is resized.

You must explicitly assign values to I<grow_mode>.

See: I<gfXXXX> constants for more information on these bit settings.

=cut

  has 'grow_mode' => (
    is        => 'rw',
    isa       => Int,
    default   => 0,
  );

=item public C<< Int help_ctx >>

Holds the view's help context setting.

You must explicitly store a value here unless there is no help, in which case
I<help_ctx> will have a default of I<HC_NO_CONTEXT>.

=cut

  has 'help_ctx' => (
    is      => 'rw',
    isa     => Int,
    default => HC_NO_CONTEXT,
  );

=item public readonly C<< TView|Undef next >>

I<next> maintains a circular list pointing to the next view, in Z-order.

=cut

  has 'next' => (
    isa       => TView|Undef,
    init_arg  => undef,
    writer    => '_next',
  );

=item public C<< Int options >>

Set I<options> to determine event processing order (I<OF_PRE_PROCESS>,
I<OF_POST_PROCESS>) and to set other attributes defined by the I<ofXXXX>
constants.

=cut

  has 'options' => (
    is        => 'rw',
    isa       => Int,
    default   => 0,
  );

=item public readonly C<< TPoint origin >>

Describes the upper left corner of the view.

=cut

  has 'origin' => (
    isa       => TPoint,
    required  => 1,
    writer    => '_origin',
  );

=item public readonly C<< TGroup|Undef owner >>

Points to the I<TGroup> that owns this view.

=cut

  has 'owner' => (
    isa       => TGroup|Undef,
    init_arg  => undef,
    writer    => '_owner',
  );

=item public readonly C<< TPoint size >>

Contains the size of the view.

=cut

  has 'size' => (
    isa       => TPoint,
    required  => 1,
    writer    => '_size',
  );

=item public readonly C<< Int state >>

The I<state> bits retain information about many view options, including the
cursor shape, if the cursor is visible or if the view is selected.

See: I<sfXXXX> constants, I<< TView->set_state >>, I<< TView->get_state >>

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

=item public C<< TView->init(TRect $bounds) >>

Creates an initializes a I<TView> object and places it according to the Bounds
parameter.

You may wish to directly assign values other than defaults, to I<state>,
I<options>, I<event_mask>, I<grow_mode> and I<drag_mode>.

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

=item public C<< TView->load(TStream $s) >>

Creates and reads a view from stream I<$s>.

=cut

  factory load(TStream $s) {
    my $origin_x = do {                                   # Read origin x value
      $s->read(my $buf, integer->size);
      integer( $buf )->unpack;
    };
    my $origin_y = do {                                   # Read origin y value
      $s->read(my $buf, integer->size);
      integer( $buf )->unpack;
    };
    my $size_x = do {                                     # Read view x size
      $s->read(my $buf, integer->size);
      integer( $buf )->unpack;
    };
    my $size_y = do {                                     # Read view y size
      $s->read(my $buf, integer->size);
      integer( $buf )->unpack;
    };
    my $cursor_x = do {                                   # Read cursor x size
      $s->read(my $buf, integer->size);
      integer( $buf )->unpack;
    };
    my $cursor_y = do {                                   # Read cursor y size
      $s->read(my $buf, integer->size);
      integer( $buf )->unpack;
    };
    my $grow_mode = do {                                  # Read growmode flags
      $s->read(my $buf, byte->size);
      byte( $buf )->unpack;
    };
    my $drag_mode = do {                                  # Read dragmode flags
      $s->read(my $buf, byte->size);
      byte( $buf )->unpack;
    };
    my $help_ctx = do {                                   # Read help context
      $s->read(my $buf, word->size);
      word( $buf )->unpack;
    };
    my $state = do {                                      # Read state masks
      $s->read(my $buf, word->size);
      word( $buf )->unpack;
    };
    my $options = do {                                    # Read options masks
      $s->read(my $buf, word->size);
      word( $buf )->unpack;
    };
    my $event_mask = do {                                 # Read event masks
      $s->read(my $buf, word->size);
      word( $buf )->unpack;
    };

    return $class->new(                                   # Call ancestor
      origin      => TPoint->new( x => $origin_x, y => $origin_y ),
      size        => TPoint->new( x => $size_x,   y => $size_y   ),
      cursor      => TPoint->new( x => $cursor_x, y => $cursor_y ),
      grow_mode   => $grow_mode,
      drag_mode   => $drag_mode,
      help_ctx    => $help_ctx,
      state       => $state,
      options     => $options,
      event_mask  => $event_mask,
    );
  };

=back

=cut

  # ------------------------------------------------------------------------
  # Destructors ------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Destructors

=over

=item public C<< DEMOLISH() >>

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

=item public C<< block_cursor() >>

Changes the cursor to the solid block cursor by setting the I<SF_CURSOR_INS>
bit in the I<state> attribute.

See: I<TView->normal_cursor>

=cut

  method block_cursor() {
    $self->set_state(SF_CURSOR_INS, _TRUE);               # Set insert mode
    return;
  }

=item public C<< calc_bounds(TRect $bounds, TPoint $delta) >>

I<calc_bounds> is used internally to resize and shape this view in the case
that the I<owner>'s view was changed in size.

=cut

  method calc_bounds(TRect $bounds, TPoint $delta) {
    my ($siz, $dlt, $min, $max);
    
    my $range = sub {
      my ($val, $min, $max) = @_;
      return $min                                         # Value below min
          if $val < $min;
      return $max                                         # Value above max
          if $val > $max;
      return $val;                                        # Accept value
    };

    my $grow_i = sub {
      alias my $i = $_[0];
      if ( $self->grow_mode & GF_GROW_REL == 0 ) {
        $i -= $dlt;
      }
      elsif ( $siz == $dlt ) {
        $i = 1;
      }
      else {
        $i = int(                                         # Calc grow value
          ($i * $siz + ($siz - $dlt) >> 1)
            /
          ($siz - $dlt)
        )
      }
    };

    $self->get_bounds($bounds);                           # Get bounds
    return                                                # No grow flags exits
        if $self->grow_mode == 0;

    $siz = $self->owner->size->x;                         # Set initial size
    $dlt = $delta->x;                                     # Set initial delta
    $grow_i->( $bounds->a->{x} )                          # Grow left side
      if $self->grow_mode & GF_GROW_LO_X != 0;
    $grow_i->( $bounds->b->{x} )                          # Grow right side
      if $self->grow_mode & GF_GROW_HI_X != 0;
    $bounds->b->{x} = $bounds->a->x + MAX_VIEW_WIDTH      # Check values
      if $bounds->b->x - bounds->a->x > MAX_VIEW_WIDTH;

    $siz = $self->owner->size->y;                         # Set initial size
    $dlt = $delta->y;                                     # Set initial delta
    $grow_i->( $bounds->a->{y} )                          # Grow top side
      if $self->grow_mode & GF_GROW_LO_Y != 0;
    $grow_i->( $bounds->b->{y} )                          # Grow lower side
      if $self->grow_mode & GF_GROW_HI_Y != 0;

    $self->size_limits($min, $max);                       # Check sizes
    $bounds->b->x(                                        # Set right side
        $bounds->a->x
      + $range->( $bounds->b->x - $bounds->a->x, $min->x, $max->x )
    );
    $bounds->b->y(                                        # Set lower side
        $bounds->a->y
      + $range->( $bounds->b->y - $bounds->a->y, $min->y, $max->y )
    );

    return;
  }

=item public C<< change_bounds(TRect $bounds) >>

This internal procedure repositions the view.

=cut

  method change_bounds(TRect $bounds) {
    $self->set_bounds($bounds);                           # Set new bounds
    $self->draw_view;                                     # Draw the view
    return;
  }

=item public C<< clear_event(TEvent $event) >>

In your I<handle_event> methods or overridden I<handle_event> methods, whenever
you have finished processing an event, you must signal that the event is
finished by calling I<clear_event>, which sets
I<< $event->what( EV_NOTHING ) >>; and I<< $event->info_ptr( $self ) >> so that
other views can determine who it was that process the event.

=cut

  method clear_event(TEvent $event)  {
    $event->what( EV_NOTHING );                           # Clear the event
    $event->info_ptr( $self );                            # Set us as handler
    return;
  }


=item public C<< Bool command_enabled(Int $command) >>

Use I<command_enabled> to check if a specific command is currently enabled or
allowed.

Pass the I<cmXXXX> value as the I<$command> parameter and I<command_enabled>
will return True if the command is available now, or False if the command has
been disabled.

=cut

  method command_enabled(Int $command) {
    return $command > 255
        || vec( $cur_command_set, $command, 1 );          # Check command
  }

=item public C<< Int data_size() >>

Used in conjunction with I<get_data> and I<set_data> to copy the views data to
and from a data record.

See: I<get_data>, I<set_data>

=cut

  method data_size() {
    return 0;                                             # Transfer size
  }

=item public C<< disable_commands(ArrayRef[Int] $commands) >>

<$commands> is a array reference containing a set of commands, specified by
their I<cmXXXX> constant values, to be disabled.

Calling I<disable_commands> causes these I<$commands> to become greyed out on
the menus and status line.

See: I<< TView->enable_commands >>

=cut

  method disable_commands(ArrayRef[Int] $commands) {
    state $empty_set = pack('b*', 0 x 256);
    $commands = do {
      my $bit_set = $empty_set;
      vec($bit_set, $_, 1) = 1 foreach @$commands;
      $bit_set;
    };
                                                          # Set changed flag
    $command_set_changed ||= ( $cur_command_set & $commands ) ne $empty_set;
    $cur_command_set &= ~$commands;                       # Update command set
    return;
  }

=item public C<< drag_view(TEvent $event, Int $mode, TRect $limits, TPoint $min_size, TPoint $max_size) >>

I<drag_view> handles redrawing the view while it is being dragged across the
string.

I<$limits> defines the rectangle in which the view can be dragged, and
I<min_size> and I<max_size> set the minimum and maximum sizes to which the view
can be resized.

=cut

  method drag_view(TEvent $event, Int $mode, TRect $limits, TPoint $min_size,
                   TPoint $max_size)
  {
    my ( $p, $s );
    my $save_bounds;

    my $move_grow = sub ($$) {
      my ( $p, $s ) = @_;
      my $r;

      $s->x( min( max( $s->x, $min_size->x ), $max_size->x ) );
      $s->y( min( max( $s->y, $min_size->y ), $max_size->y ) );

      $p->x( min( max( $p->x, $limits->a->x - $s->x+1 ), $limits->b->x-1 ) );
      $p->y( min( max( $p->y, $limits->a->y - $s->y+1 ), $limits->b->y-1 ) );

      $p->x( max( $p->x, $limits->a->x ) )
        if $mode and DM_LIMIT_LO_X != 0;

      $p->y( max( $p->y, $limits->a->y ) )
        if $mode and DM_LIMIT_LO_Y != 0;

      $p->x( min( $p->x, $limits->b->x - $s->x ) )
        if $mode and DM_LIMIT_HI_X != 0;

      $p->y( min( $p->y, $limits->b->y - $s->y ) )
        if $mode and DM_LIMIT_HI_Y != 0;

      $r->assign( $p->x, $p->y, $p->x + $s->x, $p->y + $s->y );
      $self->locate($r);
    };
    
    my $change = sub($$) {
      my ( $dx, $dy ) = @_;

      if ( $mode & DM_DRAG_MOVE != 0 ) {
        if ( get_shift_state & 0x03 == 0 ) {
          $p->x( $p->x + $dx );
          $p->y( $p->y + $dy );
        }
        elsif ( get_shift_state & 0x03 != 0 ) {
          $s->x( $s->x + $dx );
          $s->y( $s->y + $dy );
        }
      }
    };

    my $update = sub ($$) {
      my ($x, $y) = @_;
      if ( $mode & DM_DRAG_MOVE != 0 ) {
        $p->x( $x );
        $p->y( $y );
      }
    };

    $self->set_state(SF_DRAGGING, _TRUE);
    if ( $event->what == EV_MOUSE_DOWN ) {
      if ( $mode & DM_DRAG_MOVE != 0 ) {
        $p = TPoint->new(
          x => $self->origin->x - event->where->x,
          y => $self->origin->y - event->where->y,
        );
        do {
          $event->where( $event->where + $p );
          $move_grow->( $event->where, $self->size );
        } while ( not $self->mouse_event($event, EV_MOUSE_MOVE) );
        # we need to process the mouse-up event, since not all terminals
        # send drag events.
        $event->where( $event->where + $p );
        $move_grow->( $event->where, $self->size );
      }
      else {
        $p = TPoint->new(
          x => $self->size->x - event->where->x,
          y => $self->size->y - event->where->y,
        );
        do {
          $event->where( $event->where + $p );
          $move_grow->( $self->origin, $event->where );
        } while ( not $self->mouse_event($event, EV_MOUSE_MOVE) );
        # we need to process the mouse-up event, since not all terminals
        # send drag events.
        $event->where( $event->where + $p );
        $move_grow->( $self->origin, $event->where );
      }
    }
    else {
      $self->get_bounds($save_bounds);
      do {
        $p = $self->origin->clone;
        $s = $self->size->clone;
        $self->key_event($event);
        SWITCH: for ( $event->key_code & 0xff00 ) {
          $_ == KB_LEFT && do {
            $change->( -1, 0 );
            last;
          };
          $_ == KB_RIGHT && do {
            $change->( 1, 0 );
            last;
          };
          $_ == KB_UP && do {
            $change->( 0, -1 );
            last;
          };
          $_ == KB_DOWN && do {
            $change->( 0, 1 );
            last;
          };
          $_ == KB_CTRL_LEFT && do {
            $change->( -8, 0 );
            last;
          };
          $_ == KB_CTRL_RIGHT && do {
            $change->( 8, 0 );
            last;
          };
          $_ == KB_HOME && do {
            $update->( $limits->a->x, $p->y );
            last;
          };
          $_ == KB_END && do {
            $update->( $limits->b->x - $s->x, $p->y );
            last;
          };
          $_ == KB_PG_UP && do {
            $update->( $p->x, $limits->a->y );
            last;
          };
          $_ == KB_PG_DN && do {
            $update->( $p->x, $limits->b->y - $s->y );
            last;
          };
        }
        $self->move_grow($p, $s);
      } while ( $event->key_code == KB_ENTER || $event->key_code == KB_ESC );
      $self->locate($save_bounds)
        if $event->key_code == KB_ESC;
    }
    $self->set_state(SF_DRAGGING, _FALSE);
    
    return;
  }

=item public C<< draw() >>

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

Call I<get_clip_rect> to fetch the coordinates of the minimum area that needs
updating.

The use of I<get_clip_rect> can noticeably improve performance by minimizing the
amount of time spent updating the screen.

See: I<< TView->draw_view >>, I<< TView->get_clip_rect >>

=cut

  method draw() {
    my $b = [];
    move_char($b, ' ', $self->get_color(1), $self->size->x);
    $self->write_line(0, 0, $self->size->x, $self->size->y, $b);
    return;
  }

=item public C<< draw_view() >>

I<draw_view> is the preferred method to call when you need to update the view.

That's because I<draw_view> makes a check to determine if the view is exposed
(not hidden behind another view) before attempting to call I<draw>.

I<draw> doesn't care if the view is visible since Turbo Vision will
automatically clip away text that doesn't currently appear in a view.

See: I<< TView->draw >>

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

=item public C<< enable_commands(ArrayRef[Int] $commands) >>

<$commands> is a array reference containing a set of commands, specified by
their I<cmXXXX> constant values, to be enabled.

I<enable_commands> is the inverse of I<disable_commands> and restores commands
to an operable state.

See: I<< TView->enable_commands >>

=cut

  method enable_commands(ArrayRef[Int] $commands) {
    state $empty_set = pack('b*', 0 x 256);
    $commands = do {
      my $bit_set = $empty_set;
      vec($bit_set, $_, 1) = 1 foreach @$commands;
      $bit_set;
    };
                                                          # Set changed flag
    $command_set_changed ||= ( $cur_command_set & $commands ) ne $commands;
    $cur_command_set |= $commands;                        # Update command set
    return;
  }

=item public C<< end_modal(Int $command) >>

Used internally in conjunction with I<exec_view> for displaying modal views,
such as dialogs, to terminate the modal view.

See: I<< TGroup->end_modal >>, I<< TGroup->execute >>, I<< TGroup->exec_view >>

=cut

  method end_modal(Int $command) {
    my $p = $self->top_view;                              # Get top view
    $p->end_modal($command)                               # End modal operation
      if defined $p;
    return;
  }

=item public C<< Bool event_avail() >>

Returns True if an event is available.

=cut

  method event_avail() {
    my $event = TEvent->new();
    $self->get_event($event);                             # Get next event
    $self->put_event($event)                              # Put it back
      if $event->what != EV_NOTHING; 
    return $event->what != EV_NOTHING;                    # Return result
  }

=item public C<< Int execute() >>

I<execute> is overridden in I<TGroup> descendants to provide the event loop that
makes the view a modal view.

See: I<< TGroup->end_modal >>, I<< TGroup->execute >>, I<< TGroup->exec_view >>

=cut

  method execute() {
    return CM_CANCEL;                                     # Return cancel
  }

=item public C<< Bool exposed() >>

If at least some part of the view can be seen on the screen, then I<exposed>
returns True.

If the view is completely hidden, then I<exposed> returns False.

=cut

  method exposed() {
    if ( $self->state & SF_EXPOSED != 0
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



=item public C<< hide() >>

Hides the view.

See: I<< TView->show >>

=cut

  method hide () {
    $self->set_state(SF_VISIBLE, _FALSE)                  # Hide the view
      if $self->state & SF_VISIBLE != 0;                  # View is visible
    return;
  }

  method set_state(Int $a_state, Bool $enable) {
    return;
  }
  
=back

=head2 Inheritance

Methods inherited from class C<Object>

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