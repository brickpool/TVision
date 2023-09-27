=pod

=head1 NAME

TurboVision::Drivers::Types - Types for I<Drivers>

=head1 SYNOPSIS

  use TurboVision::Drivers::Types;
  ...

=cut

package TurboVision::Drivers::Types;

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
use namespace::autoclean;

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Moose::Util::TypeConstraints;
use MooseX::Types -declare => [qw(
  MouseEventType
  TSysErrorFunc
  TVideoBuf
  TVideoCell
  TVideoMode

  StdioCtl
  TEvent
  THardwareInfo
  Video

  TKeyboardDriver
  TMouseDriver
  TVideoDriver
  TSystemDriver
)];
use MooseX::Types::Structured qw( Dict );

use TurboVision::Const qw( :platform );
use TurboVision::Objects::Types qw( TPoint );

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 THE TYPES

=head2 Basic Types

=over

=item I<MouseEventType>

  subtype MouseEventType : Dict[
    buttons => Int, where => TPoint, event_flags => Int
  ];

The I<MouseEventType> is used internally for the hardware mouse driver.

=cut

subtype MouseEventType,
  as Dict[
    buttons     => Int,
    where       => TPoint,
    event_flags => Int,
  ];

=item I<TSysErrorFunc>

  subtype TSysErrorFunc : CodeRef;

I<TSysErrorFunc> defines what the system error handler function looks like. 
See I<$sys_error_func> and I<system_error> for details of intercepting system
level errors.

=cut

subtype TSysErrorFunc,
  as CodeRef;

=item I<TVideoCell>

  subtype TVideoCell : Int;

I<TVideoCell> describes one character on the screen. One of the bytes contains
the color attribute with which the character is drawn on the screen, and the
other byte contains the ASCII code of the character to be drawn.

The exact position the high byte represents the color attribute, while the
low-byte represents the ASCII code of the character to be drawn.

=cut

subtype TVideoCell,
  as Int;

=item I<TVideoBuf>

  subtype TVideoBuf : ArrayRef[TVideoCell];

The I<TVideoBuf> type represents the screen.

=cut

subtype TVideoBuf,
  as ArrayRef[TVideoCell];

=item I<TVideoMode>

  subtype TVideoMode : Dict[ col => Int, row => Int, color => Bool ];

The I<TVideoMode> describes a video mode. Its fields are self-explaining: I<col>,
I<row> describe the number of columns and rows on the screen for this mode.
I<color> is True if this mode supports colors, or False if not.

=cut

subtype TVideoMode,
  as Dict[
    col   => Int,                               # Number of columns for display
    row   => Int,                               # Number of rows for display
    color => Bool,                              # Color support
  ];

=back

=cut

=head2 Object Types

The I<Drivers> type hierarchy looks like this

  Moose::Object
    StdioCtl *)
    TEvent
    THardwareInfo
    Video

  *) Win32 only

=cut

if( _TV_UNIX ){

}elsif( _WIN32 ){

class_type StdioCtl, {
  class => 'TurboVision::Drivers::Win32::StdioCtl'
};

}#endif _TV_UNIX

class_type TEvent, {
  class => 'TurboVision::Drivers::Event'
};

class_type THardwareInfo, {
  class => 'TurboVision::Drivers::HardwareInfo'
};

class_type Video, {
  class => 'TurboVision::Drivers::Video'
};

=back

=cut

=head2 Role Types

API interface roles for the I<Drivers> module

  Moose::Role
    TKeyboardDriver
    TMouseDriver
    TVideoDriver
    TSystemDriver

=cut

role_type TKeyboardDriver, {
  role => 'TurboVision::Drivers::API::Keyboard'
};

role_type TMouseDriver, {
  role => 'TurboVision::Drivers::API::Mouse'
};

role_type TVideoDriver, {
  role => 'TurboVision::Drivers::API::Video'
};

role_type TSystemDriver, {
  role => 'TurboVision::Drivers::API::System'
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

2021,2023 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

I<MooseX::Types>, I<Drivers>, 
L<drivers.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/drivers.pas>
