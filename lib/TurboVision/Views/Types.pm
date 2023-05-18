=pod

=head1 NAME

Types - Types for I<Views>

=cut

package TurboVision::Views::Types;

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

use MooseX::Types::Moose qw( :all );

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use MooseX::Types -declare => [qw(
  TDrawBuffer
)];
use namespace::autoclean;

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 THE TYPES

=head2 Basic Types

=over

=item public type C<< TDrawBuffer >>

I<TDrawBuffer> is used to create temporary storage areas for a line of text to
be written to the screen where the low byte of each word contains the character
value, and the high byte contains the video attribute byte.

You can use the Turbo Vision sub routines, I<move_buf>, I<move_char>,
I<move_c_str>, and I<move_str> to set up the buffer and then use one of the
I<TView> method's I<write_buf> and I<write_line> within a I<draw> method to
write the output to the screen.

Here's an example using I<TDrawBuffer>:

  my $buffer = [];
  ...
  move_str($buffer, 'Financial Results for FY1991', get_color(1) );
  $self->write_line( 1, 3, 28, 1, $buffer );

See: I<TView> methods I<write_buf> and I<write_line>.

=cut

subtype TDrawBuffer,
  as ArrayRef[Ref];

=back

=cut

=head2 Object Types

The Views type hierarchy looks like this

  TObject
    TView

=cut

#class_type TView, {
#  class => 'TurboVision::Views::View'
#};

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

I<MooseX::Types>, I<Views>, 
L<views.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/views.pas>
