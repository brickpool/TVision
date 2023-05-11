=pod

=head1 NAME

TurboVision::Drivers::Win32::Screen - Windows Video Display Manager

=head1 SYNOPSIS

  use 5.014;
  use TurboVision::Drivers::Screen qw( :all );
  
  init_video();
  say "screen width:\t$screen_width";
  say "screen height:\t$screen_height";
  ...
  done_video();

=cut

package TurboVision::Drivers::Win32::Screen;

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
use PerlX::Assert;

use TurboVision::Const qw( :bool );
use TurboVision::Drivers::Const qw(
  :smXXXX
  :private
);
use TurboVision::Drivers::Types qw( StdioCtl );
use TurboVision::Drivers::Win32::StdioCtl;
use TurboVision::Drivers::Win32::LowLevel qw(
  GWL_STYLE
  WS_SIZEBOX
  GetWindowLong
  SetWindowLong
);

use Win32::Console;

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
      
    :screen
      clear_screen
      done_video
      init_video
      set_video_mode

    :private
      $_startup_mode
      _ctr_cols
      _ctr_rows
      _detect_video
      _fix_crt_mode
      _get_crt_mode
      _get_cursor_type
      _set_crt_data
      _set_crt_mode
      _set_cursor_type

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
  )],

  screen => [qw(
    clear_screen
    done_video
    init_video
    set_video_mode
  )],

  private => [qw(
    $_startup_mode
    _ctr_cols
    _ctr_rows
    _detect_video
    _fix_crt_mode
    _get_crt_mode
    _get_cursor_type
    _set_crt_data
    _set_crt_mode
    _set_cursor_type
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

=item public readonly C<< Ref screen_buffer >>

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

=item private C<< Int $_startup_mode >>

This internal variable stores the existing screen mode before Turbo Vision
switches to a new screen mode.

See: I<screen_mode>

=cut

  our $_startup_mode = 0xffff;

=begin comment

=item local C<< Object $_io >>

STD ioctl object I<< StdioCtl->instance() >>

=end comment

=cut

  my $_io;

=begin comment

=item local C<< Int $_startup_resize_mode >>

This internal variable stores the existing mode of a console's input buffer
before Turbo Vision switches to a new screen mode.

=end comment

=cut

  my $_startup_resize_mode = -1;

=back

=cut

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutines

=over

=item public C<< clear_screen() >>

After I<init_video> has been called by I<< TApplication->init >>, this
routine will clear the screen. However, most Turbo Vision applications will have
no need to use this routine.

=cut

  func clear_screen() {
    my $CONSOLE = $_io->out;
    $CONSOLE->Cls($ATTR_NORMAL);
    return;
  }

=item public C<< done_video() >>

This internal routine is called automatically by I<< TApplication->DEMOLISH >>
and terminates Turbo Vision's video support.

=cut

  func done_video() {
    return
        if $_startup_mode == 0xffff;
      
    if ( $_startup_mode != $screen_mode ) {
      _set_crt_mode( $_startup_mode );
    }
    clear_screen();
    _set_cursor_type( $cursor_lines );                  # Restore cursor shape
    $_startup_mode = 0xffff;                            # Reset the startup mode

    return
        if $_startup_resize_mode == -1;
      
    # Restore buffer size settings
    my $CONSOLE = $_io->in();
    my $resize_mode = $CONSOLE->Mode();
    if ( $_startup_resize_mode & ENABLE_WINDOW_INPUT ) {
      $resize_mode &= ~ENABLE_WINDOW_INPUT
    }
    else {
      $resize_mode |= ENABLE_WINDOW_INPUT
    }
    $CONSOLE->Mode( $resize_mode );
    $_startup_resize_mode = -1;
    return;
  };

=item public C<< init_video() >>

This internal routine, called by I<< TApplication->init >>, initialize's Turbo
Vision's video display manager and switches the display to the mode specified in
the I<screen_mode> variable.

The routine I<init_video> initializes the variables I<screen_width>,
I<screen_height>, I<hi_res_screen>, I<check_snow>, I<screen_buffer> and
I<cursor_lines>.

=cut

  func init_video() {
    my $mode = _get_crt_mode();
    if ( $_startup_mode == 0xffff ) {
      $_startup_mode = $mode;                           # Set the startup mode
      $cursor_lines = _get_cursor_type();               # Set the startup cursor
      _set_cursor_type( 0x2000 );                       # hide text-mode cursor
    }
    if ( $mode != $screen_mode ) {
      _set_crt_mode( $mode );
    }
    _set_crt_data();

    return
        if $_startup_resize_mode != -1;

    # Report changes in buffer size
    my $CONSOLE = $_io->in();
    my $resize_mode = $CONSOLE->Mode();
    $resize_mode |= ENABLE_WINDOW_INPUT;
    $CONSOLE->Mode( $resize_mode | ENABLE_WINDOW_INPUT );
    $_startup_resize_mode = $resize_mode;
    return;
  };

=item public C<< set_video_mode(Int $mode) >>

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

  func set_video_mode(Int $mode) {
    $mode = _fix_crt_mode($mode);                       # Correct the mode
    _set_crt_mode($mode);
    _set_crt_data();
    return;
  }

=item private C<< Int _ctr_cols() >>

Returns the number of columns or 0 in case of error.

This routine is in addition to the modified I<_get_crt_mode> routine.

=cut

  func _ctr_cols() {
    assert { is_Object( $_io ) };

    my $width;
    $width = $_io->get_size->{x} // 0;
    $width = 0    if $width <= 1;
    $width = 0xff if $width >  0xff;

    return $width;
  }

=item private C<< Int _ctr_rows() >>

Returns the number of rows or 0 in case of error.

This routine is in addition to the modified I<_get_crt_mode> routine.

=cut

  func _ctr_rows() {
    assert { is_Object( $_io ) };

    my $height;
    $height = $_io->get_size->{y} // 0;
    $height = 0    if $height <= 1;
    $height = 0xfe if $height >  0xfe;

    return $height;
  }

=item private C<< _detect_video() >>

Detect video modes.

=cut

  func _detect_video() {
    my $mode = _get_crt_mode();                         # Get current mode
    $mode = _fix_crt_mode($mode);                       # Correct the mode
    $screen_mode = $mode;                               # Set screen mode attr
  }

=begin comment

=item private C<< _disable_window_resizing() >>

See: L<Disable Window Resizing Win32|https://stackoverflow.com/a/27037192/12342329>

=end comment

=cut

  func _disable_window_resizing() {
    my $CONSOLE = $_io->out;
    my $hWnd = $CONSOLE->{handle};
  
    my $dwStyle = GetWindowLong($hWnd, GWL_STYLE);
    warn "SetWindowLong failed"
      if !SetWindowLong($hWnd, GWL_STYLE, $dwStyle & ~WS_SIZEBOX);
  
    return;
  }

=item public C<< Int _fix_crt_mode(Int $mode) >>

Fix CRT mode in I<$mode> if required.

If possible, PC-standard text modes are used. If not, the return of I<$mode> is
in the form I<0xHHWW>, where I<HH> is a number of rows and I<WW> is a number of
columns. E.g. 1950h (0x1950) corresponds to a C<80x25> mode.

=cut

  func _fix_crt_mode(Int $mode) {
    my $resolution;

    # Get the screen resolution
    $resolution = $mode >= 0x1000 && $mode <= 0x7fff
                ? $mode                                 # Coded in "0xHHWW" form
                : _SCREEN_RESOLUTION->( $mode )         # PC-standard text modes
                ;
    $resolution //= 80 | 25 << 8;                       # Default resolution

    # Set PC-standard text mode, if possible
    return _STANDARD_CRT_MODE->( $resolution ) // $resolution;
  }

=item private C<< Int _get_crt_mode() >>

Return CRT mode.

=cut

  func _get_crt_mode() {
    my $height = _ctr_rows();
    my $width  = _ctr_cols();

    return $width >= 40 && $height >= 24 ? $width | $height << 8
          :                                SM_CO80      # Default mode
          ;                               
  }

=item private C<< Int _get_cursor_type() >>

Return the shape of the cursor, like interrupt
L<int 10h|https://en.wikipedia.org/wiki/INT_10H> function 03h does.

=cut

  func _get_cursor_type() {
    # Get windows console cursor appearance
    my $CONSOLE = $_io->out;
    my (undef, undef, $size, $visible) = $CONSOLE->Cursor();
    $size    //= 0;
    $visible &&= $size;

    my $cursor;
    if ( $visible ) {
      # 1. A Windows Console use percentage of the character cell that is
      #    filled. This value is between 1 and 100. So 15 is a
      #    normal underline cursor, 100 is a full-block cursor.
      # 2. For int 10h a character cell has 8 scan lines (0..7), so 0x0607 is a
      #    normal underline cursor, 0x0007 is a full-block cursor
      my $scan_row_start = 0x07 - int( $size * 7.0/(100-1) + 0.5 );
      my $scan_row_end   = 0x07;
      $cursor = $scan_row_start << 8 | $scan_row_end;
    }
    else {
      # If bit 5 of "Scan Row Start" is set, that this means "Hide cursor"
      $cursor = 0x2000;
    }

    return $cursor;
  };

=item private C<< _set_crt_data() >>

Set CRT data areas

=cut

  func _set_crt_data() {
    # set the screen variables
    $screen_mode   = _get_crt_mode();                   # Set screen mode
    $screen_width  = _ctr_cols;                         # Set screen width
    $screen_height = _ctr_rows;                         # Set screen height
    $hi_res_screen = $screen_width > 25;                # Set hires variable
                                                        # Set CGA snow
    $check_snow    = !( $screen_mode == SM_MONO || $hi_res_screen );
    $screen_buffer = {};                                # Init screen buffer
  }

=item private C<< _set_crt_mode(Int $mode) >>

Set CRT mode to value in I<$mode>.

See: L<Set console window size on Windows|https://stackoverflow.com/a/25916844/12342329>

=cut

  func _set_crt_mode(Int $mode) {
    my $resolution = _SCREEN_RESOLUTION->( $mode ) // $mode;
    my $CONSOLE = $_io->out;

    my $oldr = _ctr_rows();
    my $oldc = _ctr_cols();

    my $cols = $resolution & 0xff;
    my $rows = $resolution >> 8 & 0xff;
    $cols ||= $oldc;
    $rows ||= $oldr;

    if ( $oldr <= $rows ) {
      if ( $oldc <= $cols ) {
        # increasing both dimensions
        $CONSOLE->Size( $cols, $rows );
        $CONSOLE->Window( _TRUE, 0, 0, $cols-1, $rows-1 );
      }
      else {
        # shorten width, increasing height
        $CONSOLE->Window( _TRUE, 0, 0, $cols-1, $oldr-1 );
        $CONSOLE->Size( $cols, $rows );
        $CONSOLE->Window( _TRUE, 0, 0, $cols-1, $rows-1 );
      }
    }
    else {
      if ( $oldc <= $cols ) {
        # increasing width, shorten height
        $CONSOLE->Window( _TRUE, 0, 0, $oldc-1, $rows-1 );
        $CONSOLE->Size( $cols, $rows );
        $CONSOLE->Window( _TRUE, 0, 0, $cols-1, $rows-1 );
      }
      else {
        # shorten both dimensions
        $CONSOLE->Window( _TRUE, 0, 0, $cols-1, $rows-1 );
        $CONSOLE->Size( $cols, $rows );
      }
    }
    ($cols, $rows) = $CONSOLE->Size();
    $screen_width  = $cols if $cols;
    $screen_height = $rows if $rows;

    return;
  }

=item private C<< _set_cursor_type(Int $cursor) >>

Set the shape of the cursor, as interrupt
L<int 10h|https://en.wikipedia.org/wiki/INT_10H> function 01h do.

=cut

  func _set_cursor_type(Int $cursor) {
    my $size = -1;
    # If bit 5 of "Scan Row Start" is not set, that this means "Show cursor"
    my $visible = $cursor & 0x2000 ? 0 : 1;
    
    if ( $visible ) {
      my $scan_row_start = $cursor >> 8 & 0xff;
      my $scan_row_end   = $cursor & 0xff;
      # Conversion from 0..7 to 1..100
      $size = int( ($scan_row_end - $scan_row_start) / 7.0*(100-1) + 0.5 ) + 1;
      # Correct or set usual standard values
      $size = 15  if $size < 1;                         # Underline cursor
      $size = 50  if $size == 58;                       # Half size cursor
      $size = 100 if $size > 100;                       # Full-block cursor
    }

    my $CONSOLE = $_io->out;
    $CONSOLE->Cursor(-1, -1, $size, $visible);
  };

=back

=cut

# ------------------------------------------------------------------------
# Initialization ---------------------------------------------------------
# ------------------------------------------------------------------------

INIT {
  $_io = StdioCtl->instance();
  _disable_window_resizing();

  _detect_video();
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

2021-2022 by J. Schneider L<https://github.com/brickpool/>

=item *

1992 by Ed Mitchell (Turbo Pascal Reference electronic freeware book)

=back

=head1 STOLEN CODE SNIPS

Adjustment of the window dimensions to the screen buffer or vice versa.

See: I<_ctr_cols>, I<_ctr_rows>, I<_set_crt_mode>

=over

=item *

1996-2000 by Savochenko Roman Oleksijovich E<lt>rom_as@oscada.orgE<gt>

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
