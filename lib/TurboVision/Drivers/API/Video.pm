=pod

=head1 NAME

TurboVision::Drivers::API::Video - Video driver interface

=head1 TVideoDriver

Define an "interface-only" role for the Video driver.

  requires 'clear_screen';            # Clear the screen
  requires 'set_screen_mode';         # Set the video mode
  requires 'get_screen_mode';         # Return the current video mode

  requires 'set_caret_position';      # Set the cursos position
  requires 'get_caret_size';          # Get the current cursor type
  requires 'set_caret_size';          # Set the current cursos type

  requires 'get_screen_cols';         # Return current columns
  requires 'get_screen_rows';         # Return current rows
  requires 'screen_write';            # Update physical screen
  
  requires 'allocate_screen_buffer';  # Allocate screen buffer
  requires 'free_screen_buffer';      # Done screen buffer

=cut

package TurboVision::Drivers::API::Video {
  use Moose::Role;
  use namespace::autoclean;

  requires 'clear_screen';            # Clear the screen
  requires 'set_screen_mode';         # Set the video mode
  requires 'get_screen_mode';         # Return the current video mode

  requires 'set_caret_position';      # Set the cursos position
  requires 'get_caret_size';          # Get the current cursor type
  requires 'set_caret_size';          # Set the current cursos type

  requires 'get_screen_cols';         # Return current columns
  requires 'get_screen_rows';         # Return current rows
  requires 'screen_write';            # Write to the physical screen
  
  requires 'allocate_screen_buffer';  # Returns the allocated screen buffer
  requires 'free_screen_buffer';      # Releases screen buffer resources

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

L<videoh.inc|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-console/src/inc/videoh.inc>
L<hardware.h|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/include/tvision/hardware.h>
