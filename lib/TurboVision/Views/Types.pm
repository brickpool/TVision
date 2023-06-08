=pod

=head1 NAME

TurboVision::Views::Types - Types for I<Views>

=head1 SYNOPSIS

  use TurboVision::Views::Types;
  ...

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
  TCommandSet
  TPalette
  TDrawBuffer
  TTitleStr
  TScrollChars
  TVideoBuf

  TView
  TFrame
  TScrollBar
  TScroller
  TListViewer
  TGroup
  TWindow
)];
use namespace::autoclean;

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 THE TYPES

=head2 Basic Types

=over

=item I<TCommandSet>

  subtype TCommandSet : ArrayRef[Int];

In Turbo Vision, command codes are assigned values from 0 to 65535, with
values in the range of 0 to 255 reserved for items that can be selectively
disabled.

I<TCommandSet> is used to hold a set of up to 256 commands, specifically those
that can be disabled, and is used as a parameter for the I<TView> methods,
I<enable_commands>, I<disable_commands>, I<get_commands> and I<set_commands>.

The following listing illustrates the use of a I<TCommandSet> type.

   1  # tcmdset.pl
   2  # Example using TCommandSet, from 'TVSHELL8.PAS'
   3  use Turbo::Vision::Views;
   4  use Array::Utils qw( array_minus );
   5  ...
   6    my $commands_on;
   7    my $commands_off;
   8    ...
   9    $commands_on = [ CM_USE_DOS, CM_DELETE ];
  10    $commands_off = [ @$commands_on ];
  11  
  12    if ( $set_up_data->prog_options & 2 == 2 ) {
  13      $commands_off = [ array_minus(@$commands_off, ( CM_USE_DOS )) ];
  14    }
  15  
  16    if ( $set_up_data->prog_options & 4 == 4 ) {
  17      $commands_off = [ array_minus(@$commands_off, ( CM_DELETE )) ];
  18    }
  19  
  20    $commands_on = [ array_minus(@$commands_on, @$commands_off) ];
  21  
  22    $self->disable_commands( $commands_off );
  23    $self->enable_commands( $commands_on );

=cut

subtype TCommandSet,
  as ArrayRef[Int];

=item I<TPalette>

  subtype TPalette : Str;

Defines the data type used for storing color palettes.

Since all color palettes are equivalent to strings, you can use, if you wish,
all of the various string manipulation functions, including indexing (with
C<substr>), copy (with C<=>), delete (C<undef>), insert (also C<substr>) and so
on.

=cut

subtype TPalette,
  as Str;

=item I<TDrawBuffer>

  subtype TDrawBuffer : ArrayRef[Ref];

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

=item I<TTitleStr>

  subtype TTitleStr : Str;

Defines a type used by I<TWindow> for window title strings.

=cut

subtype TTitleStr,
  as Str;

=item I<TScrollChars>

  subtype TScrollChars : Str;

This is an internal type used inside I<TScrollBar> to store the characters used
to draw a I<TScrollBar> object on the display.

=cut

subtype TScrollChars,
  as Str;

=item I<TVideoBuf>

  subtype TVideoBuf : ArrayRef[Int];

This defines the internal type used in video buffer declarations in I<TGroup>.

Video buffers are used to store screen images in cache memory (see
I<get_buf_mem>) for rapid screen update.

=cut

subtype TVideoBuf,
  as ArrayRef[Int];

=back

=cut

=head2 Object Types

The Views type hierarchy looks like this

  TObject
    TView
      TFrame
      TScrollBar
      TScroller
      TListViewer
      TGroup
        TWindow

=cut

class_type TView, {
  class => 'TurboVision::Views::View'
};
class_type TFrame, {
  class => 'TurboVision::Views::Frame'
};
class_type TScrollBar, {
  class => 'TurboVision::Views::ScrollBar'
};
class_type TScroller, {
  class => 'TurboVision::Views::Scroller'
};
class_type TListViewer, {
  class => 'TurboVision::Views::ListViewer'
};
class_type TGroup, {
  class => 'TurboVision::Views::Group'
};
class_type TWindow, {
  class => 'TurboVision::Views::Window'
};

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

L<MooseX::Types>, I<Views>, 
L<views.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/views.pas>
