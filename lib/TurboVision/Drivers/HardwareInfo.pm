=pod

=head1 NAME

TurboVision::Drivers::HardwareInfo - Turbo Vision Hardware driver

=cut

package TurboVision::Drivers::HardwareInfo;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use constant::boolean;
use Function::Parameters {
  func => {
    defaults    => 'function_strict',
    name        => 'required',
  },
},
qw(
  around
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
our $AUTHORITY = 'github:magiblot';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use English qw( -no_match_vars );
use Moose::Util::TypeConstraints;
use MooseX::Singleton;
use TurboVision::Drivers::Types qw(
  MouseEventType
  TEvent
  THardwareInfo
);
use Time::HiRes qw( time );

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<THardwareInfo> is a platform specific driver implementation that reads
keystrokes and mouse events and emits output to a screen.

The interface definition was taken from the C++ Turbo Vision library.

=head2 Class

public class I<< THardwareInfo >>

Turbo Vision Hierarchy

  Moose::Object
    THardwareInfo

=cut

package TurboVision::Drivers::HardwareInfo {

  with qw(
    TurboVision::Drivers::API::Keyboard
    TurboVision::Drivers::API::Mouse
    TurboVision::Drivers::API::Video
    TurboVision::Drivers::API::System
  );

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Attributes

Hardware attributes.

=over

=item I<_pending_event>

  field '_pending_event' => ( is => rw, isa => Int ) = 0;

=cut
  
  has '_pending_event' => (
    is        => 'rw',
    isa       => Int,
    init_arg  => undef,
    default   => 0,
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => __PACKAGE__;

  around instance() {
    return $self->$orig();
  }

  # ------------------------------------------------------------------------
  # Destructors ------------------------------------------------------------
  # ------------------------------------------------------------------------

  around _clear_instance() {
    return $self->$orig();
  }

=back

=cut

  # ------------------------------------------------------------------------
  # THardwareInfo ----------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 System functions

System functions adopted from the C++ Turbo Vision library.

=over

=item I<get_tick_count>

  method get_tick_count() : Int

The I<get_tick_count> function returns the number of timer ticks (1 second =
18.2 ticks), similar to the direct memory access to the BIOS low memory address
C<0x40:0x6C>.

=cut

  method get_tick_count() {
    return int( ( time() - $BASETIME ) * 18.2 );
  }
  
=item I<get_platform>

  method get_platform() : Str

The name of the operating system under which this copy of Perl was built, as
determined during the configuration process.

See also: I<$^O>

=cut

  method get_platform() {
    return $OSNAME;
  }

=item I<set_ctrl_brk_handler>

  method set_ctrl_brk_handler(Bool $install) : Bool

=cut

  method set_ctrl_brk_handler(Bool $install) {
    !!0
  }

=item I<set_crit_error_handler>

  method set_crit_error_handler(Bool $install) : Bool

=cut

  method set_crit_error_handler(Bool $install) {
    !!0
  }

=back

=cut
  
=head2 Caret functions

Caret functions adopted from the C++ Turbo Vision library.

=over

=item I<get_caret_size>

  method get_caret_size() : Int

Get the shape for the system caret. The caret shape can be a line, a halfblock,
a block or hidden.

=cut

  method get_caret_size() {
    0
  }

=item I<is_caret_visible>

  method is_caret_visible() : Bool

Return true if the caret is visible.

=cut

  method is_caret_visible() {
    !!0
  }

=item I<set_caret_position>

  method set_caret_position(Int $x, Int $y)

Moves the caret to the specified coordinates.

=cut

  method set_caret_position(Int $x, Int $y) {
    return;
  }

=item I<set_caret_size>

  method set_caret_size( Int $size )

Set the shape for the system caret. The caret shape can be a line, a halfblock,
a block or hidden.

=cut

  method set_caret_size(Int $size) {
    return;
  }

=back

=cut
  
=head2 Screen functions

Screen functions adopted from the C++ Turbo Vision library.

=item I<allocate_screen_buffer>

  method allocate_screen_buffer() : ArrayRef

This function should initialize any data structures needed for the functionality
of the driver, maybe do some allocation.

The function is guaranteed to be called only once; It can only be called again
after a call to L</free_screen_buffer>.

The function L</get_screen_rows> and L</get_screen_cols> should be implemented
correctly for a call of this function, as the I<allocate_screen_buffer> call
will initialize the video buffer array based on their values.

=cut

  method allocate_screen_buffer() {
    []
  }

=item I<clear_screen>

  method clear_screen(Int $w, Int $h)

If there is a faster way to clear the screen than to write spaces in all
character cells, then it can be implemented here.

If the driver does not implement this function, then the general routines will
write spaces in all video cells, and will call I<_update_screen(TRUE)>.

=cut

  method clear_screen(Int $w, Int $h) {
    return;
  }

=item I<free_screen_buffer>

  method free_screen_buffer()

This should clean up the video buffer data structures that have been initialized
with the L</allocate_screen_buffer> function.

The video buffer array will be cleared by the I<free_screen_buffer> call.

=cut

  method free_screen_buffer() {
    return;
  }

=item I<get_screen_cols>

  method get_screen_cols() : Int

=cut

  sub get_screen_cols {
    0;
  }

=item I<get_screen_mode>

  method get_screen_mode() : Int

=cut

  method get_screen_mode() {
    0
  }

=item I<get_screen_rows>

  method get_screen_rows() : Int

=cut

  sub get_screen_rows {
    0;
  }

=item I<screen_write>

  method screen_write(Int $x, Int $y, ArrayRef $buf, Int $len)

=cut

  method screen_write(Int $x, Int $y, ArrayRef $buf, Int $len) {

    # bits 0-3  The foreground color.
    #           Can be set using all color constants.
    # bits 4-6  The background color.
    #           Can be set using a subset of the color constants.
    # bit 7     The blinking bit.
    #           If this bit is set, the character will appear blinking.

    return;
  }

=item I<set_screen_mode>

  method set_screen_mode(Int $mode)

=cut

  method set_screen_mode(Int $mode) {
    return;
  }

=back

=cut

=head2 Mouse functions

Mouse functions adopted from the C++ Turbo Vision library.

=item I<cursor_off>

  method cursor_off()

=cut

  method cursor_off() {
    return;
  }

=item I<cursor_on>

  method cursor_on()

=cut

  method cursor_on() {
    return;
  }

=item I<get_button_count>

  method get_button_count() : Int

=cut

  method get_button_count() {
    0
  }

=back

=cut

=head2 Event functions

Event functions adopted from the C++ Turbo Vision library.

=item I<clear_pending_event>

  method clear_pending_event()

=cut

  method clear_pending_event() {
    $self->_pending_event(0);
    return;
  }

=item I<get_key_event>

  method get_key_event(TEvent $event) : Bool

=cut

  method get_key_event(TEvent $event) {
    !!1
  }

=item I<get_mouse_event>

  method get_mouse_event(MouseEventType $me) : Bool

=cut

  method get_mouse_event(MouseEventType $me) {
    !!1
  }

=item I<get_shift_state>

  method get_shift_state() : Int

=cut

  method get_shift_state() {
    0
  }

=back

=head2 Inheritance

Methods inherited from class L<MooseX::Singleton>

  instance, initialize, _clear_instance

Methods inherited from class L<Moose::Object>

  new, BUILDARGS, does, DOES, dump, DESTROY

=cut

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Turbo Vision library.

 Copyright (c) 2019-2021 by magiblot

 This library content was taken from the framework
 "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.

=head1 AUTHORS

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

=head1 MAINTAINER

=over

=item *

2023 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

L<hardware.h|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/include/tvision/hardware.h>
