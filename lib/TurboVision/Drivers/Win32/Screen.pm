=pod

=head1 NAME

TurboVision::Drivers::Win32::Screen - Windows Video Display Manager

=head1 DESCRIPTION

This module implements I<ScreenManager> routines for the Windows platform. A
direct use of this module is not intended. All important information is
described in the associated POD of the calling module.

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
use TurboVision::Drivers::ScreenManager qw( :vars );

use TurboVision::Drivers::Win32::StdioCtl;
#use TurboVision::Drivers::Win32::LowLevel qw(
#  GWL_STYLE
#  WS_SIZEBOX
#  GetConsoleWindow
#  GetWindowLong
#  SetWindowLong
#);

use Win32::Console;

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all
  
    :screen
      clear_screen
      done_video
      init_video
      set_video_mode

    :private
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

  screen => [qw(
    clear_screen
    done_video
    init_video
    set_video_mode
  )],

  private => [qw(
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
  
=begin comment

=head2 Variables

=over

=item I<$_io>

  my $_io = < StdioCtl >;

STD ioctl object I<< StdioCtl->instance() >>

=end comment

=cut

  my $_io;

=begin comment

=item I<$_startup_console_mode>

  my $_startup_console_mode = < Int >;

This internal variable stores the existing mode of a console's input buffer
before Turbo Vision switches to a new screen mode.

=end comment

=cut

  my $_startup_console_mode;

=begin comment

=back

=end comment

=cut

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutines

=over

=item I<clear_screen>

  func clear_screen()

This internal routine implements I<clear_screen> for I<Windows>; more
information about the routine is described in the module I<ScreenManager>.

=cut

  func clear_screen() {
    my $CONSOLE = do {
      $_io //= StdioCtl->instance();
      $_io->out();
    };
    $CONSOLE->Cls($ATTR_NORMAL);
    return;
  }

=item I<done_video>

  func done_video()

This internal routine implements I<done_video> for I<Windows>; more
information about the routine is described in the module I<ScreenManager>.

=cut

  func done_video() {
    return
        if $startup_mode == 0xffff;
      
    if ( $startup_mode != $screen_mode ) {
      _set_crt_mode( $startup_mode );
    }
    clear_screen();
    _set_cursor_type( $cursor_lines );                  # Restore cursor shape
    $startup_mode = 0xffff;                            # Reset the startup mode

    return
        unless defined $_startup_console_mode;
      
    # Restore buffer size settings
    my $CONSOLE = do {
      $_io //= StdioCtl->instance();
      $_io->in();
    };
    my $mode = $CONSOLE->Mode();
    if ( $_startup_console_mode & ENABLE_WINDOW_INPUT ) {
      $mode &= ~ENABLE_WINDOW_INPUT
    }
    else {
      $mode |= ENABLE_WINDOW_INPUT
    }
    $CONSOLE->Mode( $mode );
    $_startup_console_mode = undef;
    return;
  };

=item I<init_video>

  func init_video()

This internal routine implements I<init_video> for I<Windows>; more
information about the routine is described in the module I<ScreenManager>.

=cut

  func init_video() {
    my $mode = _get_crt_mode();
    if ( $startup_mode == 0xffff ) {
      $startup_mode = $mode;                           # Set the startup mode
      $cursor_lines = _get_cursor_type();               # Set the startup cursor
      _set_cursor_type( 0x2000 );                       # hide text-mode cursor
    }
    if ( $mode != $screen_mode ) {
      _set_crt_mode( $mode );
    }
    _set_crt_data();

    return
        if defined $_startup_console_mode;

    # Report changes in buffer size
    my $CONSOLE = do {
      $_io //= StdioCtl->instance();
      $_io->in();
    };
    $mode = $CONSOLE->Mode();
    $_startup_console_mode = $mode;
    $mode |= ENABLE_WINDOW_INPUT;
    $CONSOLE->Mode( $mode );
    return;
  };

=item I<set_video_mode>

  func set_video_mode(Int $mode)

This internal routine implements I<set_video_mode> for I<Windows>; more
information about the routine is described in the module I<ScreenManager>.

=cut

  func set_video_mode(Int $mode) {
    $mode = _fix_crt_mode($mode);                       # Correct the mode
    _set_crt_mode($mode);
    _set_crt_data();
    return;
  }

=item I<_ctr_cols>

  func _ctr_cols() : Int

Returns the number of columns or 0 in case of error.

This routine is in addition to the modified I<_get_crt_mode> routine.

=cut

  func _ctr_cols() {
    $_io //= StdioCtl->instance();
    assert { is_Object( $_io ) };

    my $width;
    $width = $_io->get_size->{x} // 0;
    $width = 0    if $width <= 1;
    $width = 0xff if $width >  0xff;

    return $width;
  }

=item I<_ctr_rows>

  func _ctr_rows() : Int

Returns the number of rows or 0 in case of error.

This routine is in addition to the modified I<_get_crt_mode> routine.

=cut

  func _ctr_rows() {
    $_io //= StdioCtl->instance();
    assert { is_Object( $_io ) };

    my $height;
    $height = $_io->get_size->{y} // 0;
    $height = 0    if $height <= 1;
    $height = 0xfe if $height >  0xfe;

    return $height;
  }

=item I<_detect_video>

  func _detect_video()

Detect video modes.

=cut

  func _detect_video() {
    my $mode = _get_crt_mode();                         # Get current mode
    $mode = _fix_crt_mode($mode);                       # Correct the mode
    $screen_mode = $mode;                               # Set screen mode attr
    return;
  }

=item I<_fix_crt_mode>

  func _fix_crt_mode(Int $mode) : Int

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

=item I<_get_crt_mode>

  func _get_crt_mode() : Int

Return CRT mode.

=cut

  func _get_crt_mode() {
    my $height = _ctr_rows();
    my $width  = _ctr_cols();

    return $width >= 40 && $height >= 24
          ? $width | $height << 8
          : SM_CO80                                     # Default mode
          ;                               
  }

=item I<_get_cursor_type>

  func _get_cursor_type() : Int

Return the shape of the cursor, like interrupt
L<int 10h|https://en.wikipedia.org/wiki/INT_10H> function 03h does.

=cut

  func _get_cursor_type() {
    # Get windows console cursor appearance
    my $CONSOLE = do {
      $_io //= StdioCtl->instance();
      $_io->out();
    };
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

=begin comment

=item I<_get_windows_resizing>

  func _get_windows_resizing() : Bool

Does the window have a resize frame?

=end comment

=cut

  #func _get_windows_resizing() {
  #  my $hWnd = GetConsoleWindow() || return undef;
  #  my $dwStyle = GetWindowLong($hWnd, GWL_STYLE) || 0;
  #  return
  #      !!( $dwStyle & ~WS_SIZEBOX )
  #};

=item I<_set_crt_data>

  func _set_crt_data()

Set CRT data areas.

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
    return;
  }

=item I<_set_crt_mode>

  func _set_crt_mode(Int $mode)

Set CRT mode to value in I<$mode>.

See: L<Set console window size on Windows|https://stackoverflow.com/a/25916844>

=cut

  func _set_crt_mode(Int $mode) {
    my $resolution = _SCREEN_RESOLUTION->( $mode ) // $mode;
    my $CONSOLE = do {
      $_io //= StdioCtl->instance();
      $_io->out();
    };

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

=item I<_set_cursor_type>

  func _set_cursor_type(Int $cursor)

Set the shape of the cursor, as interrupt
L<int 10h|https://en.wikipedia.org/wiki/INT_10H> function 01h do.

=cut

  func _set_cursor_type(Int $cursor) {
    my $size = -1;
    # If bit 5 of "Scan Row Start" is not set, that this means "Show cursor"
    my $visible = $cursor & 0x2000
                ? 0
                : 1
                ;
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

    my $CONSOLE = do {
      $_io //= StdioCtl->instance();
      $_io->out();
    };
    $CONSOLE->Cursor(-1, -1, $size, $visible);
    
    return;
  };

=begin comment

=item I<_set_window_resizing>

  func _set_window_resizing(Bool $enable)

Enable or disable the Window resize frame.

See: L<Disable Window Resizing Win32|https://stackoverflow.com/a/27037192>
and L<Change Win32 Window Style|https://stackoverflow.com/a/50083595>

=end comment

=cut

  #func _set_window_resizing(Bool $enable) {
  #  my $hWnd = GetConsoleWindow() || return;
  #  my $dwStyle = GetWindowLong($hWnd, GWL_STYLE) || 0;
  #  if ( $enable ) {
  #    SetWindowLong($hWnd, GWL_STYLE, $dwStyle | WS_SIZEBOX);
  #  }
  #  else {
  #    SetWindowLong($hWnd, GWL_STYLE, $dwStyle & ~WS_SIZEBOX);
  #  }
  #  return;
  #}

=back

=cut

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

=head1 AUTHORS
 
=over

=item *

2021-2023 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 CONTRIBUTOR

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
