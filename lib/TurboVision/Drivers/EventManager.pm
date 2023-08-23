=pod

=head1 NAME

TurboVision::Drivers::EventManager - Event Manager implementation

=cut

package TurboVision::Drivers::EventManager;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use constant::boolean;

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use TurboVision::Const qw( :platform );
use TurboVision::Drivers::Const qw( :kbXXXX );
use TurboVision::Objects::Point;
use TurboVision::Objects::Types qw( TPoint );

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all
  
    :vars
      $button_count
      $double_delay
      $mouse_buttons
      $mouse_int_flag
      $mouse_events
      $mouse_reverse
      $mouse_where
      $repeat_delay

    :events
      init_events
      done_events

    :kbd
      get_key_event
      get_shift_state

    :mouse
      get_mouse_event
      hide_mouse
      show_mouse

=cut

use Exporter qw(import);

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  vars => [qw(
    $button_count
    $double_delay
    $mouse_buttons
    $mouse_int_flag
    $mouse_events
    $mouse_reverse
    $mouse_where
    $repeat_delay
  )],

  events => [qw(
    init_events
    done_events
  )],

  kbd => [qw(
    get_key_event
    get_shift_state
  )],

  mouse => [qw(
    get_mouse_event
    hide_mouse
    show_mouse
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

# ------------------------------------------------------------------------
# Variables --------------------------------------------------------------
# ------------------------------------------------------------------------
  
=head2 Variables

=over

=item I<$button_count>

  our $button_count : Int;

If a mouse is installed, I<$button_count> holds the number of buttons on the
mouse.

If zero, then no mouse is installed.

Check the value of I<$button_count> when your program needs to know if a mouse
is installed.

=cut

  our $button_count = 0;

=item I<$double_delay>

  our $double_delay : Int;

The variable I<$double_delay> holds the time interval (in 1/18.2 of a second
intervals) defining how quickly two mouse clicks must occur in order to be
treated as a double click (rather than two separate single clicks).

By default, the two mouse clicks must occur with 8/18'ths of a second to be
considered a double click event (with I<< TEvent->double >> set to I<TRUE>).

B<Note>: For Windows, the value is the current double-click time of the system (by
default 9 ticks, equivalent to 500ms).

=cut

  our $double_delay = 8;

=item I<$mouse_buttons>

  our $mouse_buttons : Int;

Contains the current state of the mouse buttons.

See the I<mbXXXX> constants for the bit settings in this variable.

=cut

  our $mouse_buttons = 0;

=item I<$mouse_events>

  our $mouse_events : Bool;

The I<init_events> procedure detects the prescence of a mouse, and if a mouse
is found, sets I<$mouse_events> to I<TRUE>.

If no mouse is found, then I<$mouse_events> is set to I<FALSE> and no mouse
event processing occurs.

=cut

  our $mouse_events = FALSE;

=item I<$mouse_int_flag>

  our $mouse_int_flag : Int;

This is an internal variable used by Turbo Vision.

=cut

  our $mouse_int_flag = 0;

=item I<$mouse_reverse>

  our $mouse_reverse = < Bool >;

When set to I<TRUE>, this field causes the I<< TEvent->buttons >> field to
reverse the I<MB_LEFT_BUTTON> and I<MB_RIGHT_BUTTON> flags.

=cut

  our $mouse_reverse = FALSE;

=item I<$mouse_where>

  our $mouse_where : TPoint;

This I<TPoint>-typed variable is set by the mouse handler and contains the
coordinates of the mouse in global or screen coordinates.

You can convert the coordinates to view or window relative coordinates
using the I<< TView->make_local >> method.

=cut

  our $mouse_where = TPoint->new();

=item I<$repeat_delay>

  our $repeat_delay : Int;

Determines the number of clock ticks that must occur before generating an
I<EV_MOUSE_AUTO> event.

I<EV_MOUSE_AUTO> events are automatically generated while the mouse button is
held down.

A clock tick is 1/18.2 seconds, so the default value of 8/18.2 is set at
approximately 1/2 second.

See: I<evXXXX> constants, L</$double_delay>

B<Note>: The value is not used in Windows.

=cut

  our $repeat_delay = 8;

=back

=cut

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutines

=over

=item I<init_events>

  func init_events()

This internal procedure initializes Turbo Vision's mouse event handler, and
initializes and displays the mouse, if installed.

I<init_events> is automatically called by I<< TApplication->Init >>, and is
terminated by calling its corresponding L</done_events> procedure.

=cut

  sub init_events {
if( _TV_UNIX ){

}elsif( _WIN32 ){

    require TurboVision::Drivers::Win32::EventQ;
    goto &TurboVision::Drivers::Win32::EventQ::init_events;

}#endif _TV_UNIX
    return;
  }

=item I<done_events>

  func done_events()

This is a Turbo Vision internal routine that will not normally be used by your
applications.

I<done_events> disables the mouse event handler and hides the mouse.

=cut

  sub done_events {
if( _TV_UNIX ){

}elsif( _WIN32 ){

    require TurboVision::Drivers::Win32::EventQ;
    goto &TurboVision::Drivers::Win32::EventQ::done_events;

}#endif _TV_UNIX
    return;
  }

=item I<get_key_event>

  func get_key_event(TEvent $event)

Emulates the BIOS function INT 16h, Function 01h "Read LowLevel Status" to
determine if a key has been pressed on the keyboard.

If so, I<< $event->what >> is set to I<EV_KEY_DOWN> and I<< $event->key_code >>
is set to the scan code of the key.

If no keys have been pressed, I<< $event->what >> is set to I<EV_NOTHING>.

This is an internal procedure called by I<< TProgram->get_event >>.

See: I<evXXXX> constants

=cut

  sub get_key_event {
if( _TV_UNIX ){

}elsif( _WIN32 ){

    require TurboVision::Drivers::Win32::Keyboard;
    goto &TurboVision::Drivers::Win32::Keyboard::get_key_event;

}#endif _TV_UNIX
    return;
  }

=item I<get_shift_state>

  func get_shift_state() : Int

Returns a integer (octal) containing the current shift key state. The return
value contains a combination of the I<kbXXXX> constants for shift states.

=cut

  sub get_shift_state {
if( _TV_UNIX ){

}elsif( _WIN32 ){

    require TurboVision::Drivers::Win32::EventQ;
    return $TurboVision::Drivers::Win32::EventQ::_shift_state;

}#endif _TV_UNIX
    return undef;
  }

=item I<get_mouse_event>

  func get_mouse_event(TEvent $event)

Similar to I<get_key_event>, but for mouse events.

This internal routine checks Turbo Vision's internal mouse event queue, and if a
mouse event has occurred, sets I<< $event->what >> to the appropriate
I<EV_MOUSE_XXXX> constant; I<< $event->buttons >> to I<MB_LEFT_BUTTON> or
I<MB_RIGHT_BUTTON>; I<< $event->double >> to True or False; and
I<< event->where >> to the mouse position in I<TApplication> coordinates.

If no mouse events have occurred, I<< $event->what >> is set to I<EV_NOTHING>.

=cut

  sub get_mouse_event {
if( _TV_UNIX ){

}elsif( _WIN32 ){

    require TurboVision::Drivers::Win32::Mouse;
    goto &TurboVision::Drivers::Win32::Mouse::get_mouse_event;

}#endif _TV_UNIX
    return;
  }

=item I<hide_mouse>

  func hide_mouse()

This routine is used to hide the mouse, making it invisible on the screen.

Each time I<hide_mouse> is called, it increments an internal "hide" counter.

The routine I<show_mouse> decrements the internal counter and when the counter
returns to zero, the mouse cursor will reappear.

Therefore, you can nest calls to I<hide_mouse> and I<show_mouse> but there must
always be the same number of each.

=cut

  sub hide_mouse {
if( _TV_UNIX ){

}elsif( _WIN32 ){

    require TurboVision::Drivers::Win32::Mouse;
    goto &TurboVision::Drivers::Win32::Mouse::hide_mouse;

}#endif _TV_UNIX
    return;
  }

=item I<show_mouse>

  func show_mouse()

The routine I<show_mouse> is the opposite of the L</hide_mouse>.

Call L</hide_mouse> to hide the mouse cursor and simultaneously increment a
"mouse hidden counter".

The routine I<show_mouse> decrements the counter, and when it reaches zero,
makes the mouse cursor visible again on the screen.

See: L</hide_mouse>

=cut

  sub show_mouse {
if( _TV_UNIX ){

}elsif( _WIN32 ){

    require TurboVision::Drivers::Win32::Mouse;
    goto &TurboVision::Drivers::Win32::Mouse::show_mouse;

}#endif _TV_UNIX
    return;
  }

=back

=cut

# ------------------------------------------------------------------------
# Initialization ---------------------------------------------------------
# ------------------------------------------------------------------------

INIT {
if( _TV_UNIX ){

}elsif( _WIN32 ){

  require TurboVision::Drivers::Win32::Mouse;
  TurboVision::Drivers::Win32::Mouse::_detect_mouse();

}#endif _TV_UNIX
}

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Turbo Vision library.

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

2021-2023 by J. Schneider L<https://github.com/brickpool/>

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

=head1 SEE ALSO

L<drivers.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/drivers.pas>, 
L<win32con.cpp|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/source/platform/win32con.cpp>
