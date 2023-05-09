=pod

=head1 NAME

TurboVision::Drivers - Import I<TurboVision::Drivers::X> packages into one
package

=head1 SYNOPSIS

  use TurboVision::Drivers;

  # Use constant or define any objects
  ...

=cut

package TurboVision::Drivers;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Carp qw( confess );

use TurboVision::Const qw( :platform );

use TurboVision::Drivers::Const;
use TurboVision::Drivers::Types;

use if _WIN32, 'TurboVision::Drivers::Win32::EventManager';
use if _WIN32, 'TurboVision::Drivers::Win32::Keyboard';
use if _WIN32, 'TurboVision::Drivers::Win32::Mouse';
use if _WIN32, 'TurboVision::Drivers::Win32::Screen';

use Import::Into;

=head1 DESCRIPTION

I<TurboVision::Drivers> is a simple wrapper for all constants, types, routines
and classes of the I<TurboVision::Drivers::X> module hierarchy.

=head2 Modules

The following is the equivalent notation that is imported here:

  use TurboVision::Drivers::Const qw( :all !:private );
  use TurboVision::Drivers::Types qw( :all );
  use TurboVision::Drivers::Utility qw( :all );

  use TurboVision::Drivers::_::EventManager qw( :all !:private );
  use TurboVision::Drivers::_::Keyboard qw( :all );
  use TurboVision::Drivers::_::Mouse qw( :all !:private );
  use TurboVision::Drivers::_::Screen qw( :all );
  
=cut

sub import {
  my ($class, $type) = @_;
  if (defined $type) {
    confess sprintf('"%s" is not exported by the %s module', $type, $class);
  }

  my $target = caller;
  TurboVision::Drivers::Const->import::into($target, qw( :all !:private ));
  TurboVision::Drivers::Types->import::into($target, qw( :all ));
  TurboVision::Drivers::Utility->import::into($target, qw( :all ));

if( _TV_UNIX ){
  
}elsif( _WIN32 ){

  TurboVision::Drivers::Win32::EventManager->import::into($target, qw( :all !:private ));
  TurboVision::Drivers::Win32::Keyboard->import::into($target, qw( :all ));
  TurboVision::Drivers::Win32::Mouse->import::into($target, qw( :all !:private ));
  TurboVision::Drivers::Win32::Screen->import::into($target, qw( :all !:private ));

}#endif _TV_UNIX

}

sub unimport {
  my $caller = caller;
  TurboVision::Drivers::Const->unimport::out_of($caller);
  TurboVision::Drivers::Types->unimport::out_of($caller);
  TurboVision::Drivers::Utility->unimport::out_of($caller);

if( _TV_UNIX ){
  
}elsif( _WIN32 ){

  TurboVision::Drivers::Win32::EventManager->unimport::out_of($caller);
  TurboVision::Drivers::Win32::Keyboard->unimport::out_of($caller);
  TurboVision::Drivers::Win32::Mouse->unimport::out_of($caller);
  TurboVision::Drivers::Win32::Screen->unimport::out_of($caller);

}#endif _TV_UNIX

}

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

2022 by J. Schneider L<https://github.com/brickpool/>

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
