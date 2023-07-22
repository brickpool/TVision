=pod

=head1 NAME

TurboVision::Drivers::Win32::Caret - Caret functions.

=head1 DESCRIPTION

This module implements I<Caret> routines for the Windows platform. A
direct use of this module is not intended. All important information is
described in the associated POD of the calling module.

=cut

package TurboVision::Drivers::Win32::Caret;

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
our $AUTHORITY = 'github:magiblot';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Win32::Console;

use TurboVision::Drivers::Types qw( StdioCtl );
use TurboVision::Drivers::ScreenManager qw( :vars );
use TurboVision::Drivers::Win32::StdioCtl;

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all

    :caret
      done_caret
      get_caret_size
      init_caret
      is_caret_visible
      set_caret_size
      set_caret_position

=cut

use Exporter qw(import);

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  caret => [qw(
    done_caret
    get_caret_size
    init_caret
    is_caret_visible
    set_caret_position
    set_caret_size
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

=end comment

=cut

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutines

=over

=item I<done_caret>

  func done_caret()

This internal routine implements I<done_caret> for I<Windows>.

=cut

  func done_caret() {
    set_caret_size( $cursor_lines );                  # Restore cursor shape
    return;
  };

=item I<get_caret_size>

  func get_caret_size() : Int

Return the shape of the cursor, like interrupt
L<int 10h|https://en.wikipedia.org/wiki/INT_10H> function 03h does.

Note: If the cursor is not visible, the routine returns 0x2000 (bit 5 of
"Scan Row Start" is set).

=cut

  func get_caret_size() {
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

=item I<init_caret>

  func init_caret()

This internal routine implements I<init_caret> for I<Windows>.

=cut

  func init_caret() {
    if ( not defined $cursor_lines ) {
      $cursor_lines = get_caret_size();               # Set the startup cursor
      set_caret_size( 0x2000 );                       # hide text-mode cursor
    }
    return;
  };

=item I<is_caret_visible>

  func is_caret_visible() : Bool

If the cursor is hidden (bit 5 of "Scan Row Start" in L</get_caret_size> is
set), the routine returns false, otherwise true ("cursor shown").

See <L/get_caret_size>

=cut
  func is_caret_visible() {
    my $shape = get_caret_size();
    return
        not (
          ($shape & 0x2000)
            ||
          ($shape >> 8) > ($shape & 0xff)
        );
  }

=item I<set_caret_position>

  func set_caret_position(Int $x, Int $y)

Set the cursor position, as interrupt
L<int 10h|https://en.wikipedia.org/wiki/INT_10H> function 02h do.

=cut

  func set_caret_position(Int $x, Int $y) {
    # Get windows console cursor appearance
    my $CONSOLE = do {
      $_io //= StdioCtl->instance();
      $_io->out();
    };
    # Set position only
    $CONSOLE->Cursor($x, $y);
    return;
  }

=item I<set_caret_size>

  func set_caret_size(Int $cursor)

Set the shape of the cursor, as interrupt
L<int 10h|https://en.wikipedia.org/wiki/INT_10H> function 01h do.

=cut

  func set_caret_size(Int $cursor) {
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

=back

=cut

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

1994 by Borland International

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

L<hardware.h|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/include/tvision/hardware.h>, 
L<hardwrvr.cpp|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/source/tvision/hardwrvr.cpp>
