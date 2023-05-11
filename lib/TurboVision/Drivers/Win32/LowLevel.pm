=pod

=head1 NAME

TurboVision::Drivers::Win32::LowLevel - Windows low level implementation

=cut

package TurboVision::Drivers::Win32::LowLevel;

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
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use English qw( -no_match_vars );

use Win32::API;

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  GWL_STYLE
  WS_SIZEBOX

  GetDoubleClickTime

  FindWindow
  GetWindowLong
  SetWindowLong

=cut

use Exporter qw(import);

our @EXPORT_OK = qw(
  GWL_STYLE
  WS_SIZEBOX

  GetDoubleClickTime

  FindWindow
  GetWindowLong
  SetWindowLong
);

# ------------------------------------------------------------------------
# Constants --------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Constants

=over

=item public const C<< Int GWL_STYLE >>

Parameter for I<SetWindowLong>. Sets a new window style.

=cut

  use constant GWL_STYLE  => -16;

=item public const C<< Int WS_SIZEBOX >>

Defines if the window should have a sizing border.

Note: After the window is created, the style cannot be changed.

=cut

  use constant WS_SIZEBOX => 0x00040000;

=begin comment

=item private const C<< Int _userDll >>

Name of the library file used for the I<Windows and Messages> subs.

=end comment

=cut

  use constant _userDll => 'user32';

=back

=cut

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutines

=over

=item public C<< Int GetDoubleClickTime() >>

Retrieves the current double-click time for the mouse; for more info consult the
original API documentation.

=cut

BEGIN {
  Win32::API::More->Import(_userDll, 
    'UINT GetDoubleClickTime()'
  ) or die "Import GetDoubleClickTime: $EXTENDED_OS_ERROR";
}

=item public C<< Int FindWindow(Str|Undef $lpClassName, Str|Undef $lpWindowName) >>

Retrieves a handle to the top-level window whose name match the specified
strings; for more info consult the original API documentation.

=cut

BEGIN {
  Win32::API::More->Import(_userDll,
    'HWND FindWindow(LPCSTR lpClassName, LPCSTR lpWindowName)'
  ) or die "Import FindWindow: $EXTENDED_OS_ERROR";
}

=item public C<< Int GetWindowLong(Int $hWnd, Int $nIndex) >>

Retrieves a windows property; for more info consult the original API
documentation.

=cut

BEGIN {
  Win32::API::More->Import(_userDll,
    'LONG GetWindowLong(HWND hWnd, int nIndex)'
  ) or die "Import GetWindowLong: $EXTENDED_OS_ERROR";
}

=item public C<< Int SetWindowLong(Int $hWnd, Int $nIndex, Int dwNewLong) >>

Sets a windows property; for more info consult the original API documentation.

=cut

BEGIN {
  Win32::API::More->Import(_userDll,
    'LONG SetWindowLong(HWND hWnd, int nIndex, LONG dwNewLong)'
  ) or die "Import SetWindowLong: $EXTENDED_OS_ERROR";
}

=back

=cut

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Turbo Vision library.

 Interface Copyright (c) 1992 Borland International

 The library files are licensed under modified LPGL.

 The creation of subclasses of this LGPL-licensed class is considered to be
 using an interface of a library, in analogy to a function call of a library.
 It is not considered a modification of the original class. Therefore,
 subclasses created in this way are not subject to the obligations that an LGPL
 imposes on licensees.

=head1 AUTHORS
 
=over

=item *

2023 by J. Schneider L<https://github.com/brickpool/>

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

L<Keyboard and Mouse Input|https://learn.microsoft.com/en-us/windows/win32/api/_inputdev/>, 
L<Windows and Messages|https://learn.microsoft.com/en-us/windows/win32/api/_winmsg/>
