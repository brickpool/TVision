=pod

=head1 NAME

TurboVision::Drivers::ScreenManager - Video Display Manager

=head1 SYNOPSIS

  use 5.014;
  use TurboVision::Drivers::ScreenManager qw( :all );
  
  init_video();
  say "screen width:\t$screen_width";
  say "screen height:\t$screen_height";
  ...
  done_video();

=cut

package TurboVision::Drivers::ScreenManager;

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

use TurboVision::Const qw(
  :bool
  :platform
);

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all
  
    :vars
      $check_snow
      $cursor_lines
      $hi_res_screen
      $screen_buffer
      $screen_height
      $screen_mode
      $screen_width
      $startup_mode
      
    :screen
      clear_screen
      done_video
      init_video
      set_video_mode

=cut

use Exporter qw(import);

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  vars => [qw(
    $check_snow
    $cursor_lines
    $hi_res_screen
    $screen_buffer
    $screen_height
    $screen_mode
    $screen_width
    $startup_mode
  )],

  screen => [qw(
    clear_screen
    done_video
    init_video
    set_video_mode
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

=item public readonly C<< Bool $check_snow >>

If a CGA adaptor is detected, Turbo Vision sets I<check_snow> to C<TRUE>.

Older CGA video adaptor cards require special programming to avoid "snow" or
static-like lines on the display.

If the CGA video adaptor does not require snow checking, the program may set
I<check_snow> to C<FALSE>, resulting in faster output to the screen.

B<Note>: This variable is for compatiblity only.

=cut

  our $check_snow = _FALSE;

=item public readonly C<< Int $cursor_lines >>

Contains the height of the video cursor encoded such that the high 4 bits
contains the top scan line and the low 4 bits contain the bottom scan
line.

See: I<< TView->show_cursor >>, I<< TView->hide_cursor >>,
I<< TView->normal_cursor >> (to set cursor shape to an underline),
I<< TView->block_cursor >> (to set cursor to a solid block).

See: I<set_video_mode>

=cut

  our $cursor_lines = 0;

=item public readonly C<< Bool $hi_res_screen >>

Returns true if the screen supports 43 or 50 line modes, false if these
modes are not supported.

=cut

  our $hi_res_screen = _FALSE;

=item public readonly C<< Ref $screen_buffer >>

This internal reference is initialized by I<init_video> and keeps track of the
location of the video screen buffer.

See: I<screen_mode>

=cut

  our $screen_buffer = {};

=item public readonly C<< Int $screen_height >>

Holds the current height of the screen, in lines. For example, C<25>, C<43> or
C<50> would be typical values.

See: I<set_video_mode>

=cut

  our $screen_height = 0;

=item public readonly C<< Int $screen_mode >>

Contains the current video mode as determined by the I<smXXXX> constants
passed to the I<set_video_mode> routine.

See: I<set_video_mode>, I<smXXXX> constants

=cut

  our $screen_mode = 0;

=item public readonly C<< Int $screen_width >>

Holds the current width of the screen in number of characters per line (for
example, 80).

=cut

  our $screen_width = 0;

=item public readonly C<< Int $startup_mode >>

This internal variable stores the existing screen mode before Turbo Vision
switches to a new screen mode.

See: I<screen_mode>

=cut

  our $startup_mode = 0xffff;

=back

=cut

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutines

=over

=item public static C<< clear_screen() >>

After I<init_video> has been called by I<< TApplication->init >>, this
routine will clear the screen. However, most Turbo Vision applications will have
no need to use this routine.

=cut

  sub clear_screen {
if( _TV_UNIX ){

}elsif( _WIN32 ){

    require TurboVision::Drivers::Win32::Screen;
    goto &TurboVision::Drivers::Win32::Screen::_clear_screen;

}#endif _TV_UNIX
    return;
  }

=item public static C<< done_video() >>

This internal routine is called automatically by I<< TApplication->DEMOLISH >>
and terminates Turbo Vision's video support.

=cut

  sub done_video {
if( _TV_UNIX ){

}elsif( _WIN32 ){

    require TurboVision::Drivers::Win32::Screen;
    goto &TurboVision::Drivers::Win32::Screen::_done_video;

}#endif _TV_UNIX
    return;
  };

=item public static C<< init_video() >>

This internal routine, called by I<< TApplication->init >>, initialize's Turbo
Vision's video display manager and switches the display to the mode specified in
the I<screen_mode> variable.

The routine I<init_video> initializes the variables I<screen_width>,
I<screen_height>, I<hi_res_screen>, I<check_snow>, I<screen_buffer> and
I<cursor_lines>.

=cut

  sub init_video {
if( _TV_UNIX ){

}elsif( _WIN32 ){

    require TurboVision::Drivers::Win32::Screen;
    goto &TurboVision::Drivers::Win32::Screen::_init_video;

}#endif _TV_UNIX
    return;
  };

=item public static C<< set_video_mode(Int $mode) >>

Use this (or more commonly I<< TProgram->set_screen_mode >> to select 25 or
43/50 line screen height, in conjunction with selecting the color, black & white
or monochrome palettes.

To change to the color palette, write,

  $screen->set_video_mode( SM_CO80 );

where I<SM_CO80> is one of the I<smXXXX> screen mode constants.

Optionally, to select 43/50 line mode, add the I<SM_FONT8X8> constant to the
color selection constant. For example,

  $screen->set_video_mode( SM_CO80 + SM_FONT8X8 );

Normally, you should use I<< TProgram->set_screen_mode >>, which has the same
parameter value, to change the screen color or screen size.

The routine I<setscreen_mode> properly handles resetting of the application
palettes, repositioning the mouse pointer and so on.

See: I<< TProgram->set_screen_mode >>, I<smXXXX> constants

=cut

  sub set_video_mode {
if( _TV_UNIX ){

}elsif( _WIN32 ){

    require TurboVision::Drivers::Win32::Screen;
    goto &TurboVision::Drivers::Win32::Screen::_set_video_mode;

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

  require TurboVision::Drivers::Win32::Screen;
  TurboVision::Drivers::Win32::Screen::_detect_video();

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

L<drivers.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/drivers.pas>
