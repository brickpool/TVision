=pod

=head1 NAME

TurboVision::Drivers::Win32::Mouse - Windows Mouse Manager

=cut

package TurboVision::Drivers::Win32::Mouse;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use Function::Parameters {
  func => {
    defaults    => 'function_strict',
    name        => 'required',
  },
};

use MooseX::Types::Moose qw( :all );

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:fpc';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use English qw( -no_match_vars );

use TurboVision::Const qw( :bool );
use TurboVision::Drivers::Const qw(
  :evXXXX
);
use TurboVision::Drivers::Event;
use TurboVision::Drivers::StdioCtl;
use TurboVision::Drivers::Types qw(
  TEvent
  StdioCtl
);

use Win32::Console;
use Win32::API;

# ------------------------------------------------------------------------
# Imports ----------------------------------------------------------------
# ------------------------------------------------------------------------

BEGIN {
  use constant userDll => 'user32';

  Win32::API::More->Import(userDll, 
    'UINT GetDoubleClickTime()'
  ) or die "Import ReadConsoleInput: $EXTENDED_OS_ERROR";
}


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
  
    :mouse
      show_mouse
      hide_mouse

    :private
      _detect_mouse

=cut

use Exporter qw(import);

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  vars => [qw(
    $button_count
    $double_delay
    $mouse_buttons
    $mouse_events
    $mouse_int_flag
    $mouse_reverse
    $mouse_where
    $repeat_delay
  )],

  mouse => [qw(
    show_mouse
    hide_mouse
  )],
  
  private => [qw(
    _detect_mouse
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

=item public readonly C<< Int $button_count >>

If a mouse is installed, I<$button_count> holds the number of buttons on the
mouse.

If zero, then no mouse is installed.

Check the value of I<$button_count> when your program needs to know if a mouse
is installed.

=cut

  our $button_count = 0;

=item public C<< Int $double_delay >>

The variable I<$double_delay> holds the time interval (in 1/18.2 of a second
intervals) defining how quickly two mouse clicks must occur in order to be
treated as a double click (rather than two separate single clicks).

By default, the two mouse clicks must occur with 8/18'ths of a second to be
considered a double click event (with I<< TEvent->double >> set to I<TRUE>).

Note: The maximum return value under Windows is 247 (ticks).

=cut

  our $double_delay = int( GetDoubleClickTime()*1000 / 18.2 );

=item public readonly C<< Int $mouse_buttons >>

Contains the current state of the mouse buttons.

See the I<mbXXXX> constants for the bit settings in this variable.

=cut

  our $mouse_buttons = 0;

=item public readonly C<< Bool $mouse_events >>

The I<init_events> procedure detects the prescence of a mouse, and if a mouse
is found, sets I<$mouse_events> to I<TRUE>.

If no mouse is found, then $mouse_events is set to I<FALSE> and no mouse event
processing occurs.

=cut

  our $mouse_events = _FALSE;

=item public readonly C<< Int $mouse_int_flag >>

This is an internal variable used by Turbo Vision.

=cut

  our $mouse_int_flag = 0;

=item public readonly C<< Bool $mouse_reverse >>

When set to I<TRUE>, this field causes the I<< TEvent->buttons >> field to
reverse the I<MB_LEFT_BUTTON> and I<MB_RIGHT_BUTTON> flags.

=cut

  our $mouse_reverse = _FALSE;

=item public readonly C<< TPoint $mouse_where >>

This I<TPoint>-typed variable is set by the mouse handler and contains the
coordinates of the mouse in global or screen coordinates.

You can convert the coordinates to view or window relative coordinates
using the I<< TView->make_local >> method.

=cut

  our $mouse_where = TPoint->new(x => 0, y => 0);

=item public readonly C<< Int $repeat_delay >>

Determines the number of clock ticks that must occur before generating an
I<EV_MOUSE_AUTO> event.

I<EV_MOUSE_AUTO> events are automatically generated while the mouse button is
held down.

A clock tick is 1/18.2 seconds, so the default value of 8/18.2 is set at
approximately 1/2 second.

See: I<evXXXX> constants, I<$double_delay>

=cut

  our $repeat_delay = 8;

=begin comment

=item local C<< Int $_hide_count >>

Internal "hide" counter for the routines I<hide_mouse> and I<show_mouse>.

=end comment

=cut

  my $_hide_count = 0;

=begin comment

=item local C<< Object $_io >>

STD ioctl object I<< StdioCtl->instance() >>

=end comment

=cut

  my $_io;

=back

=cut

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutines

=over

=item public C<< get_mouse_event(TEvent $event) >>

Similar to I<get_key_event>, but for mouse events.

This internal routine checks Turbo Vision's internal mouse event queue, and if a
mouse event has occurred, sets I<< $event->what >> to the appropriate
I<EV_MOUSE_XXXX> constant; I<< $event->buttons >> to I<MB_LEFT_BUTTON> or
I<MB_RIGHT_BUTTON>; I<< $event->double >> to True or False; and
I<< event->where >> to the mouse position in I<TApplication> coordinates.

If no mouse events have occurred, I<< $event->what >> is set to I<EV_NOTHING>.

=cut

  func get_mouse_event(TEvent $event) {
    $event->what( EV_NOTHING );
    return;
  }

=item public C<< hide_mouse() >>

This routine is used to hide the mouse, making it invisible on the screen.

Each time I<hide_mouse> is called, it increments an internal "hide" counter.

The routine I<show_mouse> decrements the internal counter and when the counter
returns to zero, the mouse cursor will reappear.

Therefore, you can nest calls to I<hide_mouse> and I<show_mouse> but there must
always be the same number of each.

=cut

  func hide_mouse() {
    return
        if !$mouse_events;

    if ( $_hide_count == 0 ) {
      my $CONSOLE = $_io->in();
      my $mode = $CONSOLE->Mode();
      $CONSOLE->Mode($mode & ~ENABLE_MOUSE_INPUT);
    }
    $_hide_count++;

    return;
  }

=item public C<< show_mouse() >>

The routine I<show_mouse> is the opposite of the I<hide_mouse>.

Call I<hide_mouse> to hide the mouse cursor and simultaneously increment a
"mouse hidden counter".

The routine I<show_mouse> decrements the counter, and when it reaches zero,
makes the mouse cursor visible again on the screen.

See: I<hide_mouse>

=cut

  func show_mouse() {
    return
        if !$mouse_events;

    $_hide_count-- if $_hide_count > 0;
    if ( $_hide_count == 0 ) {
      my $CONSOLE = $_io->in();
      my $mode = $CONSOLE->Mode();
      $CONSOLE->Mode($mode | ENABLE_MOUSE_INPUT);
    }

    return;
  }

=item private C<< Int _detect_mouse() >>

Detect mouse driver and set I<$button_count>.

Returns the number of the buttons on your mouse, or zero on errors.

=cut

  func _detect_mouse() {
    my $CONSOLE = $_io->in();
    $button_count = $CONSOLE->MouseButtons() // 0;
    if ( $button_count ) {
      my $mode = $CONSOLE->Mode();
      $CONSOLE->Mode($mode | ENABLE_MOUSE_INPUT);
    }
    return $button_count;
  }

=back

=cut

# ------------------------------------------------------------------------
# Initialization ---------------------------------------------------------
# ------------------------------------------------------------------------

INIT {
  _detect_mouse();
}

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

1996-2000 by Leon de Boer E<lt>ldeboer@attglobal.netE<gt>

=item *

1992 by Ed Mitchell (Turbo Pascal Reference electronic freeware book)

=back

=head1 STOLEN CODE SNIPS

The Windows event mapping was taken from the framework
"A modern port of Turbo Vision 2.0", which is licensed under MIT licence

See: I<hide_mouse>, I<show_mouse>

=over

=item *

2019-2021 by magiblot E<lt>magiblot@hotmail.comE<gt>

=back

=head1 DISCLAIMER OF WARRANTIES
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.

=head1 CONTRIBUTOR

=over

=item *

2021-2022 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

L<drivers.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/drivers.pas>, 
L<win32con.cpp|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/source/platform/win32con.cpp>
