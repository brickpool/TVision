=pod

=head1 NAME

TurboVision::Drivers::Video - Video handling module for Turbo Vision

=head1 SYNOPSIS

  package VideoUtil;

  use TurboVision::Drivers::Video;
  use TurboVision::Drivers::Types qw( Video );
  use Exporter qw( import );

  our @EXPORT_OK = qw(
    text_out
  );
  
  sub text_out {
    my ($x, $y, $s) = @_;        # (Int, Int, Str)
    my ($w, $p, $i, $m);         # (Int, Int, Int, Int)
  
    $p = ($x-1) + ($y-1) * Video->screen_width;
    $m = length($s);
    if ( $p+$m > Video->screen_width * Video->screen_height
    ) {
      $m = Video->screen_width * Video->screen_heigh - $p;
    }
    for my $i (0..$m-1) {
      Video->video_buf->[$p+$i] = ord(substr($s, $i, 1) + (0x07 << 8);
    }
  }
  
  1;

=cut

package TurboVision::Drivers::Video;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use Function::Parameters qw(
  classmethod
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

use Carp;
use Data::Alias qw( alias );
use MooseX::ClassAttribute;
use MooseX::StrictConstructor;
use Try::Tiny;

use TurboVision::Const qw( :bool );
use TurboVision::Drivers::Const qw(
  :crXXXX
  :errXXXX
);
use TurboVision::Drivers::Types qw(
  TVideoBuf
  TVideoMode
  Video
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

The working of the I<Video> module is simple: After calling L</init_video>, the
ArrayRef L</video_buf> contains a representation of the video screen of size
L</screen_width> * I</screen_height>, going from left to right and top to bottom
when walking the array elements:

I<< video_buf->[0] >> contains the character and color code of the top-left
character on the screen. I<< video_buf->[screen_width] >> contains the data for
the character in the first column of the second row on the screen, and so on.

To write to the 'screen', the text to be written should be written to the
L</video_buf> Array. Calling L</update_screen> will then copy the text to the
screen in the most optimal way.

The color attribute is a combination of the foreground and background color,
plus the blink bit. The bits describe the various color combinations:

  bits 0-3  The foreground color.
            Can be set using all color constants.
  bits 4-6  The background color.
            Can be set using a subset of the color constants.
  bit 7     The blinking bit.
            If this bit is set, the character will appear blinking.

Each possible color has a constant associated with it, see the constants section
for a list of constants.

The foreground and background color can be combined to a color attribute with
the following code:

  $attr = $fore_ground_color + $back_ground-color << 4;

The color attribute can be logically or-ed with the blink attribute to produce a
blinking character:

  $attr |= 128;

But not all drivers may support this.

The contents of the L</video_buf> Array may be modified: This is 'writing' to
the screen. As soon as everything that needs to be written in the array is in
the L</video_buf> ArrayRef, calling L</update_screen> will copy the contents of
the array screen to the screen, in a manner that is as efficient as possible.

The updating of the screen can be prohibited to optimize performance; To this
end, the L</lock_screen_update> class method can be used: This will increment an
internal counter. As long as the counter differs from zero, calling
L</update_screen> will not do anything. The counter can be lowered with
L</unlock_screen_update>. When it reaches zero, the next call to
L</update_screen> will actually update the screen. This is useful when having
nested procedures that do a lot of screen writing.

The I<Video> module also presents an interface for Turbo Vision screen drivers.

Note: The I<Video> module should be used only together with the Turbo Vidion.
Doing not so will result in very strange behaviour, possibly program aborts.

=cut

=head2 Class

public class I<< Video >>

=cut

package TurboVision::Drivers::Video {

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Class Attributes

=over

=item I<error_code>

  class_has error_code ( is => rwp, type => Int ) = 0;

Error code returned by the last operation.

=cut

  class_has 'error_code' => (
    isa     => Int,
    default => ERR_OK,
    writer  => '_error_code',
  );

=item I<cursor_lines>

  class_has cursor_lines ( is => ro, type => Int );

I<cursor_lines> is a bitmask which determines which cursor lines are visible and
which are not. Each set bit corresponds to a cursorline being shown.

=cut

  class_has 'cursor_lines' => (
    isa => Int,
  );

=item I<max_width>

  class_has max_width ( is => ro, type => Int ) = < Int >;

Maximum screen buffer width.

=cut

  class_has 'max_width' => (
    isa     => Int,
    default => 240,
  );

=item I<screen_color>

  class_has screen_color ( is => ro, type => Bool ) = _TRUE;

I<screen_color> indicates whether the current screen supports colors.

=cut

  class_has 'screen_color' => (
    isa     => Bool,
    default => _TRUE,
  );

=item I<screen_height>

  class_has screen_height ( is => ro, type => Int ) = 0;

Current screen height.

=cut

  class_has 'screen_height' => (
    isa     => Int,
    default => 0,
  );

=item I<screen_width>

  class_has screen_width ( is => ro, type => Int ) = 0;

Current screen width.

=cut

  class_has 'screen_width' => (
    isa     => Int,
    default => 0,
  );

=item I<video_buf>

  class_has video_buf ( is => ro, type => TVideoBuf ) = [];

I<video_buf> forms the heart of the I<Video> module: This variable represents
the physical screen. Writing to this array and calling L</update_screen> will
write the actual characters to the screen.

=item I<video_buf_size>

  class_has video_buf_size ( is => ro, type => Int ) = 0;

Current size of the video buffer pointed to by I<video_buf>.

=cut

  class_has 'video_buf' => (
    traits  => ['Array'],
    isa     => TVideoBuf,
    default => sub { [] },
    handles => {
      video_buf_size => 'count',
    }
  );

=begin comment

=item I<_lock_level>

  class_has _lock_level ( is => rw, type => Int );

Screen lock update count.

=end comment

=cut

  class_has '_lock_level' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
  );

=begin comment

=item I<$_is_initialized>

  my $_is_initialized ( is => private, type => Bool );

Is Video initialized.

=end comment

=cut

  my $_is_initialized = _FALSE;

=begin comment

=item I<$_video_mode>

  my $_video_mode ( is => private, type => Int );

Video mode.

=end comment

=cut

  my $_video_mode;

=back

=cut

  # ------------------------------------------------------------------------
  # TStreamRec -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Class Methods

Stream interface routines

=over

=item I<clear_screen>

  classmethod clear_screen()

I<clear_screen> clears the entire screen, and calls L</update_screen> after
that. This is done by writing spaces to all character cells of the video buffer
in the default color (lightgray on black, color attribute C<0x07>).

See: L</init_video>, L</update_screen>

=cut

  classmethod clear_screen() {
    return
        if not $_is_initialized;
    try {
      confess 'Not implemented';
    }
    catch {
      $class->_error_code(0 - ERR_VIO_NOT_SUPPORTED);
      return;
    };
    $class->_error_code(ERR_OK);
    return;
  }

=item I<done_video>

  classmethod done_video()

I<done_video> disables the I<Video> driver if the video driver is active. If the
video driver was already disabled or not yet initialized, it does nothing.

Disabling the driver means it will clean up any allocated resources, possibly
restore the screen in the state it was before L</init_video> was called.
Particularly, the L</video_buf> array are no longer valid after a call to
I<done_video>.

The I<done_video> should always be called if I<init_video> was called. Failing
to do so may leave the screen in an unusable state after the program exits.

=cut

  classmethod done_video() {
    return
        if not $_is_initialized;
    try {
      confess 'Not implemented';
    }
    catch {
      $class->_error_code(0 - ERR_VIO_INIT);
      return;
    };
    $class->_error_code(ERR_OK);
    return;
  }

=item I<get_cursor_type>

  classmethod get_cursor_type() : Int

I<get_cursor_type> returns the current cursor type. It is one of the following
values:

  CR_HIDDEN     Hide cursor
  CR_UNDERLINE  Underline cursor
  CR_BLOCK      Block cursor
  CR_HALF_BLOCK Half block cursor

Note: that not all drivers support all types of cursors.

See: L</set_cursor_type>

=cut

  classmethod get_cursor_type() {
    my $type = 0;
    if ( $_is_initialized ) {
      try {
        confess 'Not implemented';
      }
      catch {
        $class->_error_code(0 - ERR_VIO_NOT_SUPPORTED);
        return 0;
      };
      $class->_error_code(ERR_OK);
    }
    return $type;
  }

=item I<get_lock_screen_count>

  classmethod get_lock_screen_count(): Int

I<get_lock_screen_count> returns the current lock level. When the lock level is
zero, a call to L</update_screen> will actually update the screen.

See L</lock_screen_update>, L</unlock_screen_update>, L</update_screen> 

=cut

  sub get_lock_screen_count() {
    goto &_lock_level;
  }

=item I<get_video_mode>

  classmethod get_video_mode(TVideoMode $mode)

I<get_video_mode> returns the settings of the currently active video mode.
The I<row>, I<col> fields indicate the dimensions of the current video mode, and
I<color> is true if the current video supports colors.

See L</set_video_mode>

=cut

  classmethod get_video_mode($) {
    alias my $mode = $_[-1];
    confess 'Invalid argument $var'
      if not is_TVideoMode $mode;

    return
        if not $_is_initialized;
    try {
      confess 'Not implemented';
    }
    catch {
      $class->_error_code(0 - ERR_VIO_NO_SUCH_MODE);
      return;
    };
    $class->_error_code(ERR_OK);
    return;
  }

=item I<init_video>

  classmethod init_video()

I<init_video> Initializes the video subsystem. If the video system was already
initialized, it does nothing. After the driver has been initialized, the
L</video_buf> ArrayRef is initialized, based on the L</screen_width> and
L</screen_height> attributes. When this is done, the screen is cleared.

If the driver fails to initialize, the L</error_code> attribute is set.

See I<done_video>.

=cut

  classmethod init_video() {
    return
        if $_is_initialized;
    try {
      confess 'Not implemented';
    }
    catch {
      $class->_error_code(0 - ERR_VIO_INIT);
      return;
    };
    $class->_error_code(ERR_OK);
    return;
  }

=item I<lock_screen_update>

  classmethod lock_screen_update()

I<lock_screen_update> increments the screen update lock count with one. As long
as the screen update lock count is not zero, L</update_screen>  will not
actually update the screen.

This function can be used to optimize screen updating: If a lot of writing on
the screen needs to be done (by possibly unknown functions), calling
I<lock_screen_update> before the drawing, and L</unlock_screen_update> after the
drawing, followed by a L</update_screen> call, all writing will be shown on
screen at once.

See L</update_screen>, L</unlock_screen_update>, L</get_lock_screen_count>

=cut

  classmethod lock_screen_update() {
    return
        if not $_is_initialized;
    $class->_lock_level # =
      ( $class->_lock_level + 1 );
    return;
  }

=item I<set_video_mode>

  classmethod set_video_mode(TVideoMode $mode) : Bool;

I<set_video_mode> sets the video mode to the mode specified in Mode:

If the call was successful, then the screen will have I<< col => columns >> and
I<< row => rows >>, and will be displaying in color if I<< color => 1 >> (color
is true).

The function returns True if the mode was set successfully, False otherwise.

Note: The video mode may not always be set. E.g. a console on Linux or a telnet
session cannot always set the mode. It is important to check the error value
returned by this function if it was not successful.

The mode can be set when the video driver has not yet been initialized (i.e.
before L</init_video> was called). In that case, the video mode will be stored,
and after the driver was initialized, an attempt will be made to set the
requested mode. Changing the video driver before the call to L</init_video> will
clear the stored video mode.

To retrieve the current video mode, use the L</get_video_mode> procedure.

See L</get_video_mode>

=cut

  classmethod set_video_mode(TVideoMode $mode) {
    try {
      confess 'Not implemented';
    }
    catch {
      $class->_error_code(0 - ERR_VIO_NO_SUCH_MODE);
      return _FALSE;
    };
    $class->_error_code(ERR_OK);
    return _TRUE;
  }

=item I<unlock_screen_update>

  classmethod unlock_screen_update()

I<unlock_screen_update> decrements the screen update lock count with one if it
is larger than zero. When the lock count reaches zero, the L</update_screen>
will actually update the screen. No screen update will be performed as long as
the screen update lock count is nonzero. This mechanism can be used to increase
screen performance in case a lot of writing is done.

It is important to make sure that each call to L</lock_screen_update> is matched
by exactly one call to I<unlock_screen_update>.

See L</lock_screen_update>, L</get_lock_screen_count>, L</update_screen>

=cut

  classmethod unlock_screen_update() {
    return
        if not $_is_initialized;
    if ( $class->_lock_level > 0 ) {
      $class->_lock_level # =
        ( $class->_lock_level - 1 );
    }
    return;
  }

=item I<update_screen>

  classmethod update_screen(Bool $force)

I<update_screen> synchronizes the actual screen with the contents of the
L</video_buf> internal buffer. The parameter Force specifies whether the whole
screen has to be redrawn (I<$force> = True) or only parts that have changed
since the last update of the screen.

The current contents of L</video_buf> are examined to see what locations on the
screen need to be updated. On slow terminals (e.g. a Linux telnet session) this
mechanism can speed up the screen redraw considerably.

On platforms where mouse cursor visibility is not guaranteed to be preserved
during screen updates this routine has to restore the mouse cursor after the
update (usually by calling I<hide_mouse> from module I<Mouse> before the real
update and I<show_mouse> afterwards).

See L</clear_screen>

=cut

  classmethod update_screen(Bool $force) {
    return
        if not $_is_initialized;
    try {
      confess 'Not implemented';
      # code
      if ( $_is_initialized ) {
        # code
      }
    }
    catch {
      $class->_error_code(0 - ERR_VIO_NOT_SUPPORTED);
      return;
    };
    $class->_error_code(ERR_OK);
    return;
  }

=back

=head2 Inheritance

Methods inherited from class L<Moose::Object>

  new, BUILDARGS, does, DOES, dump, DESTROY

=cut
  
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Free Pascal run time library.
 Copyright (c) 1999-2000 by the Free Pascal development team.

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

L<video.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-console/src/win/video.pp>
