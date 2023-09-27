=pod

=head1 NAME

TurboVision::Drivers::API::System - System driver interface

=head1 DESCRIPTION

I<TSystemDriver> define an "interface-only" role for the System driver.

  requires 'get_tick_count';          # Return tick counts
  requires 'get_platform';            # Return $^O
  requires 'set_ctrl_brk_handler';    # System CTRL-C handler

=cut

package TurboVision::Drivers::API::System {
  use Moose::Role;
  use namespace::autoclean;

  requires 'get_tick_count';          # Return tick counts
  requires 'get_platform';            # Return $^O
  requires 'set_ctrl_brk_handler';    # System CTRL-C handler

  1;
}

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Free Pascal run time library.
 Copyright (c) 1999-2005 by the Free Pascal development team.

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

1999-2000 by Florian Klaempfl E<lt>fnklaemp@cip.ft.uni-erlangen.deE<gt>

=item *

1999-2005 by Free Pascal development team

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

L<sysutilh.inc|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/rtl/objpas/sysutils/sysutilh.inc>
L<systemh.inc|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/rtl/inc/systemh.inc>
L<hardware.h|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/include/tvision/hardware.h>
