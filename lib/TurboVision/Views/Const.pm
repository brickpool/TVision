=pod

=head1 NAME

TurboVision::Views::Const - Constants used by I<Views>

=head1 SYNOPSIS

  use TurboVision::Views::Const qw(
    MAX_VIEW_WIDTH
    :sfXXXX
  );
  ...

=cut

package TurboVision::Views::Const;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:fpc';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Exporter qw( import );

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all
    MAX_VIEW_WIDTH
    
    :phXXXX
      PH_FOCUSED
      PH_PRE_PROCESS
      PH_POST_PROCESS

    :smXXXX => [qw(
      NORMAL_SELECT
      ENTER_SELECT
      LEAVE_SELECT

    :sfXXXX
      SF_VISIBLE
      SF_CURSOR_VIS
      SF_CURSOR_INS
      SF_SHADOW
      SF_ACTIVE
      SF_SELECTED
      SF_FOCUSED
      SF_DRAGGING
      SF_DISABLED
      SF_MODAL
      SF_DEFAULT
      SF_EXPOSED

    :ofXXXX
      OF_SELECTABLE
      OF_TOP_SELECT
      OF_FIRST_CLICK
      OF_FRAMED
      OF_PRE_PROCESS
      OF_POST_PROCESS
      OF_BUFFERED
      OF_TILEABLE
      OF_CENTER_X
      OF_CENTER_Y
      OF_CENTERED
      OF_VALIDATE
      OF_VERSION
      OF_VERSION_10
      OF_VERSION_20

    :gfXXXX
      GF_GROW_LO_X
      GF_GROW_LO_Y
      GF_GROW_HI_X
      GF_GROW_HI_Y
      GF_GROW_ALL
      GF_GROW_REL

    :dmXXXX
      DM_DRAG_MOVE
      DM_DRAG_GROW
      DM_LIMIT_LO_X
      DM_LIMIT_LO_Y
      DM_LIMIT_HI_X
      DM_LIMIT_HI_Y
      DM_LIMIT_ALL

    :hcXXXX
      HC_NO_CONTEXT
      HC_DRAGGING

    :sbXXXX
      SB_LEFT_ARROW
      SB_RIGHT_ARROW
      SB_PAGE_LEFT
      SB_PAGE_RIGHT
      SB_UP_ARROW
      SB_DOWN_ARROW
      SB_PAGE_UP
      SB_PAGE_DOWN
      SB_INDICATOR

      SB_HORIZONTAL
      SB_VERTICAL
      SB_HANDLE_KEYBOARD

    :wfXXXX
      WF_MOVE
      WF_GROW
      WF_CLOSE
      WF_ZOOM

    :wnXXXX
      WN_NO_NUMBER

    :wpXXXX
      WP_BLUE_WINDOW
      WP_CYAN_WINDOW
      WP_GRAY_WINDOW

    :cmXXXX
      CM_VALID
      CM_QUIT
      CM_ERROR
      CM_MENU
      CM_CLOSE
      CM_ZOOM
      CM_RESIZE
      CM_NEXT
      CM_PREV
      CM_HELP
      
      CM_CUT
      CM_COPY
      CM_PASTE
      CM_UNDO
      CM_CLEAR
      CM_TILE
      CM_CASCADE
      
      CM_OK
      CM_CANCEL
      CM_YES
      CM_NO
      CM_DEFAULT
      
      CM_RECEIVED_FOCUS
      CM_RELEASED_FOCUS
      CM_COMMAND_SET_CHANGED
      
      CM_SCROLL_BAR_CHANGED
      CM_SCROLL_BAR_CLICKED
      
      CM_SELECT_WINDOW_NUM
      
      CM_LIST_ITEM_SELECTED

      CM_CURSOR_CHANGED

    :color
      CFrame
      CScrollBar
      CScroller
      CListViewer
      CBlueWindow
      CCyanWindow
      CGrayWindow

=cut

our @EXPORT_OK = qw(
  MAX_VIEW_WIDTH
);

our %EXPORT_TAGS = (

  phXXXX => [qw(
    PH_FOCUSED
    PH_PRE_PROCESS
    PH_POST_PROCESS
  )],

  smXXXX => [qw(
    NORMAL_SELECT
    ENTER_SELECT
    LEAVE_SELECT
  )],

  sfXXXX => [qw(
    SF_VISIBLE
    SF_CURSOR_VIS
    SF_CURSOR_INS
    SF_SHADOW
    SF_ACTIVE
    SF_SELECTED
    SF_FOCUSED
    SF_DRAGGING
    SF_DISABLED
    SF_MODAL
    SF_DEFAULT
    SF_EXPOSED
  )],

  ofXXXX => [qw(
    OF_SELECTABLE
    OF_TOP_SELECT
    OF_FIRST_CLICK
    OF_FRAMED
    OF_PRE_PROCESS
    OF_POST_PROCESS
    OF_BUFFERED
    OF_TILEABLE
    OF_CENTER_X
    OF_CENTER_Y
    OF_CENTERED
    OF_VALIDATE
    OF_VERSION
    OF_VERSION_10
    OF_VERSION_20
  )],

  gfXXXX => [qw(
    GF_GROW_LO_X
    GF_GROW_LO_Y
    GF_GROW_HI_X
    GF_GROW_HI_Y
    GF_GROW_ALL
    GF_GROW_REL
  )],
  
  dmXXXX => [qw(
    DM_DRAG_MOVE
    DM_DRAG_GROW
    DM_LIMIT_LO_X
    DM_LIMIT_LO_Y
    DM_LIMIT_HI_X
    DM_LIMIT_HI_Y
    DM_LIMIT_ALL
  )],

  hcXXXX => [qw(
    HC_NO_CONTEXT
    HC_DRAGGING
  )],

  sbXXXX => [qw(
    SB_LEFT_ARROW
    SB_RIGHT_ARROW
    SB_PAGE_LEFT
    SB_PAGE_RIGHT
    SB_UP_ARROW
    SB_DOWN_ARROW
    SB_PAGE_UP
    SB_PAGE_DOWN
    SB_INDICATOR

    SB_HORIZONTAL
    SB_VERTICAL
    SB_HANDLE_KEYBOARD
  )],
  
  wfXXXX => [qw(
    WF_MOVE
    WF_GROW
    WF_CLOSE
    WF_ZOOM
  )],

  wnXXXX => [qw(
    WN_NO_NUMBER
  )],

  wpXXXX => [qw(
    WP_BLUE_WINDOW
    WP_CYAN_WINDOW
    WP_GRAY_WINDOW
  )],
  
  cmXXXX => [qw(
    CM_VALID
    CM_QUIT
    CM_ERROR
    CM_MENU
    CM_CLOSE
    CM_ZOOM
    CM_RESIZE
    CM_NEXT
    CM_PREV
    CM_HELP
    
    CM_CUT
    CM_COPY
    CM_PASTE
    CM_UNDO
    CM_CLEAR
    CM_TILE
    CM_CASCADE
    
    CM_OK
    CM_CANCEL
    CM_YES
    CM_NO
    CM_DEFAULT
    
    CM_RECEIVED_FOCUS
    CM_RELEASED_FOCUS
    CM_COMMAND_SET_CHANGED
    
    CM_SCROLL_BAR_CHANGED
    CM_SCROLL_BAR_CLICKED
    
    CM_SELECT_WINDOW_NUM
    
    CM_LIST_ITEM_SELECTED

    CM_CURSOR_CHANGED
  )],

  color => [qw(
    CFrame
    CScrollBar
    CScroller
    CListViewer
    CBlueWindow
    CCyanWindow
    CGrayWindow
  )],
  
);

# add all the other %EXPORT_TAGS ":class" tags to the ":all" class and
# @EXPORT_OK, deleting duplicates
{
  my %seen;
  push
    @EXPORT_OK,
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
        foreach keys %EXPORT_TAGS;
  push
    @{$EXPORT_TAGS{all}},
      @EXPORT_OK;
}

=head1 DESCRIPTION

tbd

=cut

# ------------------------------------------------------------------------
# Constants --------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 CONSTANTS

=head2 Constants provided by I<Views>

=over

=item I<MAX_VIEW_WIDTH>

  constant MAX_VIEW_WIDTH = < Int >;

Determines the maximum width of a view.

=cut

  use constant MAX_VIEW_WIDTH => 255;

=head2 TGroup Phase Enum constants (I<:phXXXX>)

=over

=item I<PH_FOCUSED>

  constant PH_FOCUSED = < Int >;

Process phase: I<TGroup> sets the I<phase> field to I<PH_FOCUSED> and passes the
event to the I<handle_event> method of the currently selected subview. 

=cut

  use constant PH_FOCUSED       => 0;

=item I<PH_PRE_PROCESS>

  constant PH_PRE_PROCESS = < Int >;

Pre-Processing phase: I<TGroup> sets the I<phase> field to I<PH_PRE_PROCESS> and 
passes the event to the I<handle_event> method of all subviews for which the 
L</OF_PRE_PROCESS> flag has been set. 

=cut

  use constant PH_PRE_PROCESS   => 1;

=item I<PH_POST_PROCESS>

  constant PH_POST_PROCESS = < Int >;

Pre-Processing phase: I<TGroup> sets the I<phase> field to I<PH_POST_PROCESS> 
and passes the event to the I<handle_event> method of all subviews for which the
L</OF_POST_PROCESS> flag has been set. 

=cut

  use constant PH_POST_PROCESS  => 2;

=back

=head2 TGroup SelectMode Enum constants (I<:smXXXX>)

An internal enum used by Turbo Vision.

=over

=item I<NORMAL_SELECT>

  constant NORMAL_SELECT = < Int >;

Normal selection

=cut

  use constant NORMAL_SELECT  => 0;

=item I<ENTER_SELECT>

  constant ENTER_SELECT = < Int >;

Enter selection.

=cut

  use constant ENTER_SELECT   => 1;

=item I<LEAVE_SELECT>

  constant LEAVE_SELECT = < Int >;

Leave selection.

=cut

  use constant LEAVE_SELECT   => 2;

=back

=head2 TView State Flag constants (I<:sfXXXX>)

Use I<< TView->set_state >> to set the state bits, from the table below, into a
TView's State field.

Example usage:

  $self->set_state( SF_CURSOR_INS, TRUE );

where the first parameter is the state value to change, and the second parameter
is True to enable the selected condition, or False to disable the selected
condition.

Some of the bits are not normally set by the programmer but rather by methods in
Turbo Vision.

You can, however, read and test the values in I<< TView->state >> directly.

B<See>: I<< TView->block_cursor >>, I<< TView->exposed >>, I<< TView->hide >>,
I<< TView->hide_cursor >>, I<< TView->normal_cursor >>, I<< TView->set_state >>,
I<< TView->show >>, I<< TView->show_cursor >>.

=over

=item I<SF_VISIBLE>

  constant SF_VISIBLE = < Int >;

Set when the view is visible in front of its owner (for example, a button on a
dialog) but note that a visible view's owner may itself be hidden from view.

Call I<< TView->exposed >> to determine if a view is actually visible on the
screen, and use I<< TView->hide >> to clear this bit and hide the view, and
I<< TView->show >> to set this bit and make the view visible.

=cut

  use constant SF_VISIBLE     => 0x0001;

=item I<SF_CURSOR_VIS>

  constant SF_CURSOR_VIS = < Int >;

Set when the view's cursor is visible.

Use I<< TView->show_cursor >> to make the cursor visible and set this bit, or
I<< TView->hide_cursor >> to hide the cursor and clear this bit.

=cut

  use constant SF_CURSOR_VIS  => 0x0002;

=item I<SF_CURSOR_INS>

  constant SF_CURSOR_INS = < Int >;

Set when the cursor is a solid block (the "insert" cursor), clear when the
cursor is an underscore (the "overstrike" cursor).

Call I<< TView->block_cursor >> to set this bit, and I<< TView->normal_cursor >>
to clear the bit.

=cut

  use constant SF_CURSOR_INS  => 0x0004;

=item I<SF_SHADOW>

  constant SF_SHADOW = < Int >;

Set when the view has a shadow.

=cut

  use constant SF_SHADOW      => 0x0008;

=item I<SF_ACTIVE>

  constant SF_ACTIVE = < Int >;

Set whenever the view is an active window or a subview within an active window.

For example, when using the GUI to edit multiple files, only the editor that you
are currently using is the active window.

=cut

  use constant SF_ACTIVE      => 0x0010;

=item I<SF_SELECTED>

  constant SF_SELECTED = < Int >;

Set when this view is selected. (See I<< TView->selected >>).

=cut

  use constant SF_SELECTED    => 0x0020;

=item I<SF_FOCUSED>

  constant SF_FOCUSED = < Int >;

If the view is part of the focus chain, then this bit is set.

=cut

  use constant SF_FOCUSED     => 0x0040;

=item I<SF_DRAGGING>

  constant SF_DRAGGING = < Int >;

Set whenever the view is being dragged.

=cut

  use constant SF_DRAGGING    => 0x0080;

=item I<SF_DISABLED>

  constant SF_DISABLED = < Int >;

Set if the view has been disabled and is no longer processing events.

=cut

  use constant SF_DISABLED    => 0x0100;

=item I<SF_MODAL>

  constant SF_MODAL = < Int >;

Whenever a view is displayed using the <exec_view> call, that view becomes a
modal view (as compared to a view that has been inserted into the desktop).

This bit is set when the view is the modal view and controls how events are sent
through the view hierarchy.

=cut

  use constant SF_MODAL       => 0x0200;

=item I<SF_DEFAULT>

  constant SF_DEFAULT = < Int >;

View is default.

=cut

  use constant SF_DEFAULT     => 0x0400;

=item I<SF_EXPOSED>

  constant SF_EXPOSED = < Int >;

Set when a view is possibly visible on the screen.

Don't check this flag directly because a visible view can still be hidden due to
clipping.

Instead, call I<< TView->exposed >> to determine if the view is actually
visible.

=cut

  use constant SF_EXPOSED     => 0x0800;

=back

=head2 TView Options Field bit positions (I<:ofXXXX>)

The I<ofXXXX> constants select options available in all I<TView>-derived
objects.

Setting the bit position to a 1 sets the indicated attribute; clearing the bit
position to 0 disables the indicated attributes.

=over

=item I<OF_SELECTABLE>

  constant OF_SELECTABLE = < Int >;

If this bit is set, then the view can be selected with a mouse.

While most views are normally selectable, this bit gives the option to make the
item unselectable.

An example of an unselectable view is I<TStaticText> items.

=cut

  use constant OF_SELECTABLE    => 0x0001;

=item I<OF_TOP_SELECT>

  constant OF_TOP_SELECT = < Int >;

When set, this view will move to the topmost view whenever it is selected.

This option should normally be set only for window objects.

=cut

  use constant OF_TOP_SELECT    => 0x0002;

=item I<OF_FIRST_CLICK>

  constant OF_FIRST_CLICK = < Int >;

When a mouse click is used to select a view, the click can be optionally passed
to the view after it is selected.

For example, within a dialog box, if you click on a button, you not only wish to
set the focus to that button, but you probably also want to activate the button
at the same time.

=cut

  use constant OF_FIRST_CLICK   => 0x0004;

=item I<OF_FRAMED>

  constant OF_FRAMED = < Int >;

When set, the view has visible frame drawn around it.

=cut

  use constant OF_FRAMED        => 0x0008;

=item I<OF_PRE_PROCESS>

  constant OF_PRE_PROCESS = < Int >;

This option enables views other than the focused view to have a chance at
processing an event. 

Normally, events are passed down the focus-chain, however, events are also sent
to any subviews (in Z-order) that have this bit set, giving them a chance to
process the event.

=cut

  use constant OF_PRE_PROCESS   => 0x0010;

=item I<OF_POST_PROCESS>

  constant OF_POST_PROCESS = < Int >;

When this bit is set, subviews are given a chance after the focused view, to
process events that have not yet cleared.

=cut

  use constant OF_POST_PROCESS  => 0x0020;

=item I<OF_BUFFERED>

  constant OF_BUFFERED = < Int >;

Views can optionally store an image of themselves in a memory buffer.

When the view needs to be redrawn on the screen, it can rapidly copy itself from
the buffer, rather than recreate the drawing on the screen.

To enable cache buffering of the view's displayable image, set the
I<OF_BUFFERED> bit to on.

The buffers are stored in special, disposable memory caches. When the memory
manager runs out of memory, these cache buffers are automatically deleted to
free up more memory space, and the view's recreate their displayable images as
they would without the ofBuffered option.

If you set the I<OF_BUFFERED> option, be sure to call the I<TGroup> method's
Lock and Unlock to prevent copying of the screen image to the display until all
of the subview's have drawn themselves.

B<See also>: I<get_buf_mem>, I<free_mem>

=cut

  use constant OF_BUFFERED      => 0x0040;

=item I<OF_TILEABLE>

  constant OF_TILEABLE = < Int >;

Generally, you will want window objects to be either tileable or cascadeable so
that the desktop can automatically rearrange the windows, if desired.

If you wish to disable this function for a particular view, clear this bit
position in the Options field.

When disabled, the view will not move on the screen, even if other views become
tiled or cascaded.

B<See also>: I<< TDeskTop->cascade >>, I<< TDeskTop->tile >>.

=cut

  use constant OF_TILEABLE      => 0x0080;

=item I<OF_CENTER_X>

  constant OF_CENTER_X = < Int >;

When this bit is set, the insertion of the view causes the view to be
horizontally centered.

=cut

  use constant OF_CENTER_X      => 0x0100;

=item I<OF_CENTER_Y>

  constant OF_CENTER_Y = < Int >;

When this bit is set, a view is centered in the vertical direction (especially
useful when switching between 25 and 43/50 line modes).

=cut

  use constant OF_CENTER_Y      => 0x0200;

=item I<OF_CENTERED>

  constant OF_CENTERED = < Int >;

Same as setting both I<OF_CENTER_X> and I<OF_CENTER_Y>:

centers the view in both vertical and horizontal directions.

=cut

  use constant OF_CENTERED      => 0x0300;

=item I<OF_VALIDATE>

  constant OF_VALIDATE = < Int >;

View validates.

=cut

  use constant OF_VALIDATE      => 0x0400;

=item I<OF_VERSION>

  constant OF_VERSION = < Int >;

View TV version.

=cut

  use constant OF_VERSION       => 0x3000;

=item I<OF_VERSION_10>

  constant OF_VERSION_10 = < Int >;

TV version 1 view.

=cut

  use constant OF_VERSION_10    => 0x0000;

=item I<OF_VERSION_20>

  constant OF_VERSION_20 = < Int >;

TV version 2 view.

=cut

  use constant OF_VERSION_20    => 0x1000;

=back

=head2 TView Grow mode Field constants (I<:gfXXXX>)

The I<gfXXXX> constants set the I<< TView->grow_mode >> field, which controls
how a view grows in relation to the view that own's it.

=over

=item I<GF_GROW_LO_X>

  constant GF_GROW_LO_X = < Int >;

The left side of the view will stay a constant distance from it's owner's left
side.

=cut

  use constant GF_GROW_LO_X => 0x01;

=item I<GF_GROW_LO_Y>

  constant GF_GROW_LO_Y = < Int >;

The top of the view will stay a constant distance from it's owner's top.

=cut

  use constant GF_GROW_LO_Y => 0x02;

=item I<GF_GROW_HI_X>

  constant GF_GROW_HI_X = < Int >;

The right side of the view will stay a constant distance from it's owner's right
side.

=cut

  use constant GF_GROW_HI_X => 0x04;

=item I<GF_GROW_HI_Y>

  constant GF_GROW_HI_Y = < Int >;

The bottom of the view will stay a constant distance from it's owner's bottom
side.

=cut

  use constant GF_GROW_HI_Y => 0x08;

=item I<GF_GROW_ALL>

  constant GF_GROW_ALL = < Int >;

The view should maintain the same size and move with respect to the lower right
corner of the owner.

=cut

  use constant GF_GROW_ALL  => 0x0F;

=item I<GF_GROW_REL>

  constant GF_GROW_REL = < Int >;

The view will maintain its size relative to the owner.

This flag should only be used on I<TWindow> derived objects and is intended for
keeping windows adjusted relative to their owner when switching between 25 line
mode and 43/50 line screen modes.

=cut

  use constant GF_GROW_REL  => 0x10;

=back

=head2 TView Drag Mode constants (I<:dmXXXX>)

The I<< TView->drag_mode >> attribute controls whether or not a view can be
dragged or have it size changed.

The I<drag_mode> attribute is stored as Int, with the bits set by the constants
shown in the following list, and I<$limits> is a I<TRect> parameter to
I<< TView->drag_view >>.

=over

=item I<DM_DRAG_MOVE>

  constant DM_DRAG_MOVE = < Int >;

Allow the view to move.

=cut

  use constant DM_DRAG_MOVE   => 0x01;

=item I<DM_DRAG_GROW>

  constant DM_DRAG_GROW = < Int >;

Allow the view to change size.

=cut

  use constant DM_DRAG_GROW   => 0x02;

=item I<DM_LIMIT_LO_X>

  constant DM_LIMIT_LO_X = < Int >;

The left hand side cannot move outside I<$limits> of I<< TView->drag_view >>.

=cut

  use constant DM_LIMIT_LO_X  => 0x10;

=item I<DM_LIMIT_LO_Y>

  constant DM_LIMIT_LO_Y = < Int >;

The top side cannot move outside I<$limits> of I<< TView->drag_view >>.

=cut

  use constant DM_LIMIT_LO_Y  => 0x20;

=item I<DM_LIMIT_HI_X>

  constant DM_LIMIT_HI_X = < Int >;

The right hand side cannot move outside I<$limits> of I<< TView->drag_view >>.

=cut

  use constant DM_LIMIT_HI_X  => 0x40;

=item I<DM_LIMIT_HI_Y>

  constant DM_LIMIT_HI_Y = < Int >;

The bottom side cannot move outside I<$limits> of I<< TView->drag_view >>.

=cut

  use constant DM_LIMIT_HI_Y  => 0x80;

=item I<DM_LIMIT_ALL>

  constant DM_LIMIT_ALL = < Int >;

None of the view can move outside I<$limits> of I<< TView->drag_view >>.

=cut

  use constant DM_LIMIT_ALL   => 0xf0;

=back

=head2 TView Help Contexts constants (I<:hcXXXX>)

=over

=item I<HC_NO_CONTEXT>

  constant HC_NO_CONTEXT = < Int >;

No view contex.

=cut

  use constant HC_NO_CONTEXT  => 0;

=item I<HC_DRAGGING>

  constant HC_DRAGGING = < Int >;

No drag context.

=cut
 
  use constant HC_DRAGGING    => 1;

=back

=head2 TScrollBar part codes (I<:sbXXXX>)

Use one of these nine I<sbXXXX> constants as a parameter to
I<< TScrollBar->scroll_step >>.

=over

=item I<SB_LEFT_ARROW>

  constant SB_LEFT_ARROW = < Int >;

The horizontal scroll bar's left arrow.

=cut

  use constant SB_LEFT_ARROW  => 0;

=item I<SB_RIGHT_ARROW>

  constant SB_RIGHT_ARROW = < Int >;

Horizontal scroll bar's right arrow.

=cut
 
  use constant SB_RIGHT_ARROW => 1;

=item I<SB_PAGE_LEFT>

  constant SB_PAGE_LEFT = < Int >;

The page area to the left of the position indicator.

=cut
 
  use constant SB_PAGE_LEFT   => 2;

=item I<SB_PAGE_RIGHT>

  constant SB_PAGE_RIGHT = < Int >;

The page indicator to the right of the indicator.

=cut
 
  use constant SB_PAGE_RIGHT  => 3;

=item I<SB_UP_ARROW>

  constant SB_UP_ARROW = < Int >;

Vertical scroll bar's up arrow.

=cut
 
  use constant SB_UP_ARROW    => 4;

=item I<SB_DOWN_ARROW>

  constant SB_DOWN_ARROW = < Int >;

Vertical scroll bar's down arrow.

=cut
 
  use constant SB_DOWN_ARROW  => 5;

=item I<SB_PAGE_UP>

  constant SB_PAGE_UP = < Int >;

Paging area above the position indicator.

=cut
 
  use constant SB_PAGE_UP     => 6;

=item I<SB_PAGE_DOWN>

  constant SB_PAGE_DOWN = < Int >;

Paging area below the position indicator.

=cut
 
  use constant SB_PAGE_DOWN   => 7;

=item I<SB_INDICATOR>

  constant SB_INDICATOR = < Int >;

Position indicator on the scroll bar.

=cut
 
  use constant SB_INDICATOR   => 8;

=back

=head2 TScrollBar options (I<:sbXXXX>)

The foloowing three I<sbXXXX> constants, I<SB_HORIZONTAL>, I<SB_VERTICAL>,
I<SB_HANDLE_KEYBOARD> are used to specify a horizontal, vertical, or keyboard
accessable scrollbar when a scroll bar is created using the
I<< TWindow->standard_scroll_bar >> method.

=over

=item I<SB_HORIZONTAL>

  constant SB_HORIZONTAL = < Int >;

The scroll bar is horizontal.

=cut

  use constant SB_HORIZONTAL      => 0x0000;

=item I<SB_VERTICAL>

  constant SB_VERTICAL = < Int >;

The scroll bar is vertical.

=cut

  use constant SB_VERTICAL        => 0x0001;

=item I<SB_HANDLE_KEYBOARD>

  constant SB_HANDLE_KEYBOARD = < Int >;

Scroll bar accepts keyboard commands.

=cut

  use constant SB_HANDLE_KEYBOARD => 0x0002;

=back

=head2 TWindow flags (I<:wfXXXX>)

B<See>: I<TWindow>, I<< TWindog->flags >>

=over

=item I<WF_MOVE>

  constant WF_MOVE = < Int >;

When bit is set, the window can be moved.

=cut

  use constant WF_MOVE  => 0x01;

=item I<WF_GROW>

  constant WF_GROW = < Int >;

When the bit is set, the window can be resized and has a "grow" icon in the
lower right corner.

If you clear this bit you can prevent a window from being resized.

=cut

  use constant WF_GROW  => 0x02;

=item I<WF_CLOSE>

  constant WF_CLOSE = < Int >;

Set this bit to add a close icon in the upper left corner of a window.

Clear the bit to eliminate the icon.

=cut

  use constant WF_CLOSE => 0x04;

=item I<WF_ZOOM>

  constant WF_ZOOM = < Int >;

When this bit is set, the window contains a zoom icon for zooming a window to
full size.

=cut

  use constant WF_ZOOM  => 0x08;

=back

=head2 TWindow number constants (I<:wnXXXX>)

=over

=item I<WN_NO_NUMBER>

  constant WN_NO_NUMBER = < Int >;

When ever a I<< TWindow->number >> attribute contains this value, it means that
the window has no number.

Windows that have no number do not display any number in the upper right corner,
nor can they be selected with the Alt-number quick key selection for switching
between windows numbered 1 through 9.

=cut

  use constant WN_NO_NUMBER => 0x01;

=back

=head2 TWindow Palette selection contstants (I<:wpXXXX>)

I<TWindows> has three different color palettes, as shown below. 

  CBlueWindow (indicated by WP_BLUE_WINDOW) is normally used for text windows,
  CCyanWindow (indicated by WP_CYAN_WINDOW) is normally used for messages, and
  CGrayWindow (indicated by WP_GRAY_WINDOW) is normally used for dialog boxes.
  
The I<wpXXXX> constant, indicating the window color scheme, is stored in
I<< TWindow->palette >>.

You can alter a window's default color scheme, by assigning one of the I<wpXXXX>
constants to I<< TWindow->palette >>, typically after calling the window's
I<init> constructor.

Example, where DirWindow is I<TWindow>-derived object:

  DirWindow->palette( WP_CYAN_WINDOW );

=over

=item I<WP_BLUE_WINDOW>

  constant WP_BLUE_WINDOW = < Int >;

Yellow on blue color scheme.

=cut

  use constant WP_BLUE_WINDOW => 0;

=item I<WP_CYAN_WINDOW>

  constant WP_CYAN_WINDOW = < Int >;

Blue on cyan color scheme.

=cut

  use constant WP_CYAN_WINDOW => 1;

=item I<WP_GRAY_WINDOW>

  constant WP_GRAY_WINDOW = < Int >;

Black on gray color scheme.

=cut

  use constant WP_GRAY_WINDOW => 2;

=back

=head2 Command codes (I<:cmXXXX>)

=over

=item Standard command codes

  Constant    Value
  CM_VALID    0
  CM_QUIT     1
  CM_ERROR    2
  CM_MENU     3
  CM_CLOSE    4
  CM_ZOOM     5
  CM_RESIZE   6
  CM_NEXT     7
  CM_PREV     8
  CM_HELP     9

=cut

  use constant {
    CM_VALID   => 0,
    CM_QUIT    => 1,
    CM_ERROR   => 2,
    CM_MENU    => 3,
    CM_CLOSE   => 4,
    CM_ZOOM    => 5,
    CM_RESIZE  => 6,
    CM_NEXT    => 7,
    CM_PREV    => 8,
    CM_HELP    => 9,
  };

  
=item Application command codes

  Constant    Value
  CM_CUT      20
  CM_COPY     21
  CM_PASTE    22
  CM_UNDO     23
  CM_CLEAR    24
  CM_TILE     25
  CM_CASCADE  26

=cut

  use constant {
    CM_CUT     => 20,
    CM_COPY    => 21,
    CM_PASTE   => 22,
    CM_UNDO    => 23,
    CM_CLEAR   => 24,
    CM_TILE    => 25,
    CM_CASCADE => 26,
  };

=item TDialog standard commands

  Constant    Value
  CM_OK       10
  CM_CANCEL   11
  CM_YES      12
  CM_NO       13
  CM_DEFAULT  14

=cut

  use constant {
    CM_OK      => 10,
    CM_CANCEL  => 11,
    CM_YES     => 12,
    CM_NO      => 13,
    CM_DEFAULT => 14,
  };

=item TView standard messages

  Constant                Value
  CM_RECEIVED_FOCUS       50
  CM_RELEASED_FOCUS       51
  CM_COMMAND_SET_CHANGED  52

=cut

  use constant {
    CM_RECEIVED_FOCUS       => 50,
    CM_RELEASED_FOCUS       => 51,
    CM_COMMAND_SET_CHANGED  => 52,
  };

=item TScrollBar messages

  Constant              Value
  CM_SCROLL_BAR_CHANGED 53
  CM_SCROLL_BAR_CLICKED 54

=cut

  use constant {
    CM_SCROLL_BAR_CHANGED => 53,
    CM_SCROLL_BAR_CLICKED => 54,
  };

=item TWindow messages

  Constant              Value
  CM_SELECT_WINDOW_NUM  55

=cut

  use constant {
    CM_SELECT_WINDOW_NUM => 55,
  };

=item TListViewer messages

  Constant              Value
  CM_LIST_ITEM_SELECTED 56

=cut

  use constant {
    CM_LIST_ITEM_SELECTED => 56,
  };

=item Additional messages

  Constant            Value
  CM_CURSOR_CHANGED   700

=cut

  use constant {
    CM_CURSOR_CHANGED => 700,
  };

=back

=head2 Color Palette constants (I<:color>)

Except for I<CColor>, I<CBlackWhite> and I<CMonoChrome>, all of the color
palette constants contains indices into their owner's palette.

For I<CColor>, I<CBlackWhite> and I<CMonoChrome>, each entry contains a BIOS
video color attribute byte equivalent.

You can use these color palette maps to determine what color a particular
object or component will have when it appears on the screen.

For example, if you place a I<TButton> object into a I<TDialog> object, you can
trace through the color palettes to determine what color it will have.

A "normal" button will have the attribute "Text Normal" shown in the first byte
of the I<CButton> color palette.

This color entry is an index into its owner's palette, I<CDialog>.

Looking at the 10th entry of I<CDialog>, we see that this maps to entry 41 in
the application-level palette.

In the case of I<CColor> (color display in use), this corresponds to black
lettering on a green background.

=over

=item I<CFrame>

  constant CFrame = < Str >;

Frame palette

  Byte Usage           Maps to     On this palette
  [ 1] Passive frame   1           Standard window palettes
  [ 2] Passive Title   1
  [ 3] Active Frame    2
  [ 4] Active Title    2
  [ 5] Icons           3

=cut

  use constant CFrame       => pack('C*',1,1,2,2,3);

=item I<CScrollBar>

  constant CScrollBar = < Str >;

Scrollbar palette

  Byte Usage             Maps to   On this palette
  [ 1] Page              4         Application palette
  [ 2] Arrows            5
  [ 3] Indicator         5

=cut

  use constant CScrollBar   => pack('C*',4,5,5);

=item I<CScroller>

  constant CScroller = < Str >;

Scroller palette

  Byte Usage             Maps to   On this palette
  [ 1] Normal            6         Application palette
  [ 2] Highlight         7

=cut

  use constant CScroller    => pack('C*',6,7);

=item I<CListViewer>

  constant CListViewer = < Str >;

Listviewer palette used for TListViewer and TLIistBox

  Byte Usage           Maps to     On this palette
  [ 1] Active          26          Application palette
  [ 2] Inactive        26
  [ 3] Focused         27
  [ 4] Selected        28
  [ 5] Divider         29

=cut

  use constant CListViewer  => pack('C*',26,26,27,28,29);

=item I<CBlueWindow>

  constant CBlueWindow = < Str >;

Blue window palette

  Byte Usage                    Maps to   On this palette
  [ 1] Frame Passive            8         Application palette
  [ 2] Frame Active             9
  [ 3] Frame Icon               10
  [ 4] ScrollBar page           11
  [ 5] ScrollBar reserved       12
  [ 6] Scroller Normal Text     13
  [ 7] Scroller Selected Text   14
  [ 8] Reserved                 15

=cut

  use constant CBlueWindow  => pack('C*',8,9,10,11,12,13,14,15);

=item I<CCyanWindow>

  constant CCyanWindow = < Str >;

Cyan window palette

  Byte Usage                    Maps to   On this palette
  [ 1] Frame Passive            16        Application palette
  [ 2] Frame Active             17
  [ 3] Frame Icon               18
  [ 4] ScrollBar page           19
  [ 5] ScrollBar reserved       20
  [ 6] Scroller Normal Text     21
  [ 7] Scroller Selected Text   22
  [ 8] Reserved                 23

=cut

  use constant CCyanWindow  => pack('C*',16,17,18,19,20,21,22,23);

=item I<CGrayWindow>

  constant CGrayWindow = < Str >;

Cyan window palette

  Byte Usage                    Maps to   On this palette
  [ 1] Frame Passive            24        Application palette
  [ 2] Frame Active             25
  [ 3] Frame Icon               26
  [ 4] ScrollBar page           27
  [ 5] ScrollBar reserved       28
  [ 6] Scroller Normal Text     29
  [ 7] Scroller Selected Text   30
  [ 8] Reserved                 31

=cut

  use constant CGrayWindow  => pack('C*',24,25,26,27,28,29,30,31);

=back

=cut

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

2023-2024 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

I<Exporter>, I<Views>, 
L<views.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/views.pas>
