=pod

=head1 NAME

TurboVision::Drivers::API::Keyboard - Keyboard driver interface

=head1 TKeyboardDriver

Define an "interface-only" role for the Keyboard driver.

  requires 'get_key_event';       # Get the next key event (non blocking)
  requires 'get_shift_state';     # Get the current shift state

=cut

package TurboVision::Drivers::API::Keyboard {
  use Moose::Role;
  use namespace::autoclean;

  requires 'get_key_event';       # Get the next key event (non blocking)
  requires 'get_shift_state';     # Get the current shift state

  1;
}

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Free Pascal run time library.
 Copyright (c) 1999-2000 by the Free Pascal development team.

 Interface Copyright (c) 1994 Borland International

 The run-time files are licensed under modified LGPL.
 
 The creation of subclasses of this LGPL-licensed class is considered to be
 using an interface of a library, in analogy to a function call of a library.
 It is not considered a modification of the original class. Therefore,
 subclasses created in this way are not subject to the obligations that an LGPL
 imposes on licensees.

=head1 AUTHORS

=over

=item *

1999-2000 by Free Pascal development team

=back

=head1 CONTRIBUTOR

The interface definition was taken from the framework
L<A modern port of Turbo Vision 2.0|https://github.com/magiblot/tvision>, which
is licensed under MIT licence

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

L<keybrdh.inc|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-console/src/inc/keybrdh.inc>
L<hardware.h|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/include/tvision/hardware.h>
