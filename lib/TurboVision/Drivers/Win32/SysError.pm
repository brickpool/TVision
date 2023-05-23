=pod

=head1 NAME

TurboVision::Drivers::Win32::SysError - System Error Handler implementation

=head1 DESCRIPTION

This module implements I<SystemError> routines for the Windows platform. A
direct use of this module is not intended. All important information is
described in the associated POD of the calling module.

=cut

package TurboVision::Drivers::Win32::SysError;

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
use Data::Alias qw( alias );

use TurboVision::Const qw( :bool );
use TurboVision::Drivers::Types qw( StdioCtl );
use TurboVision::Drivers::SystemError qw( :vars );
use TurboVision::Drivers::Win32::StdioCtl;

use Win32::Console;

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all

    :syserr
      init_sys_error
      done_sys_error
      system_error

=cut

use Exporter qw(import);

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  syserr => [qw(
    init_sys_error
    done_sys_error
    system_error
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
# Constants --------------------------------------------------------------
# ------------------------------------------------------------------------

=begin comment

=head2 Constants

=over

=item private const C<< Int _MB_ICONERROR >>

A stop-sign icon appears in the message box.

=end comment

=cut

  use constant _MB_ICONERROR      => 0x00000010;

=begin comment

=item private const C<< Int _MB_RETRYCANCEL >>

The message box contains two push buttons: Retry and Cancel.

=end comment

=cut

  use constant _MB_RETRYCANCEL    => 0x00000005;

=begin comment

=item private const C<< Int _MB_SETFOREGROUND >>

The message box becomes the foreground window.

=end comment

=cut

  use constant _MB_SETFOREGROUND  => 0x00010000;

=begin comment

=item private const C<< Int _IDRETRY >>

The Retry button was selected.

=end comment

=cut

  use constant _IDRETRY           => 4;

=begin comment

=back

=end comment

=cut

# ------------------------------------------------------------------------
# Variables --------------------------------------------------------------
# ------------------------------------------------------------------------
  
=begin comment

=head2 Variables

=over

=item private C<< Object $_io >>

STD ioctl object I<< StdioCtl->instance() >>

=end comment

=cut

  my $_io;

=begin comment

=back

=end comment

=cut

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutines

=over

=item I<init_sys_error>

  func init_sys_error()

This internal routine implements I<init_sys_error> for I<Windows>; more
information about the routine is described in the module I<SystemError>.

=cut

  func init_sys_error() {
    my $CONSOLE = do {
      $_io //= StdioCtl->instance();
      $_io->in();
    };

    my $mode = $CONSOLE->Mode();                        # save Ctrl+C status
    $save_ctrl_break = !!( $mode & ENABLE_PROCESSED_INPUT );
    $CONSOLE->Mode( $mode & ~ENABLE_PROCESSED_INPUT );  # Report Ctrl+C and ...
                                                        # ... Shift+Arrow events
    $sys_err_active = _TRUE;

    return;
  }

=item I<done_sys_error>

  func done_sys_error()

This internal routine implements I<done_sys_error> for I<Windows>; more
information about the routine is described in the module I<SystemError>.

=cut

  func done_sys_error() {
    return
        if not $sys_err_active;
    $sys_err_active = _FALSE;

    my $CONSOLE = do {
      $_io //= StdioCtl->instance();
      $_io->in();
    };

    my $mode = $CONSOLE->Mode();                        # restore Ctrl-C status
    if ( $save_ctrl_break ) {
      $CONSOLE->Mode( $mode | ENABLE_PROCESSED_INPUT )
    }
    else {
      $CONSOLE->Mode( $mode & ~ENABLE_PROCESSED_INPUT )
    }

    return;
  }

=item I<system_error>

  func system_error(Int $error_code, Int $drive) : Int

This internal routine implements I<system_error> for I<Windows>; more
information about the routine is described in the module I<SystemError>.

=cut

  func system_error(Int $error_code, Int $drive) {
    return 1                                          # Return 1 for ignored
        if $fail_sys_errors;                          # Check error ignore

    if ( $error_code >= 0
      && $error_code <= 15
      && $error_code == $EXTENDED_OS_ERROR-19
    ) {
      $drive = chr($drive + ord 'A');
      my $str = $EXTENDED_OS_ERROR;
      $str =~ s/\%1/$drive/;
      my $choice = Win32::MsgBox(
        $str, _MB_ICONERROR | _MB_SETFOREGROUND | _MB_RETRYCANCEL, ''
      );
      return $choice == _IDRETRY
            ? 0
            : 1
            ;
    }

    return;
  }

=back

=cut

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

=head1 AUTHORS

=over

=item *

1996-2000 by Leon de Boer E<lt>ldeboer@attglobal.netE<gt>

=back

=head1 CONTRIBUTOR

The Windows event mapping was taken from the framework
"A modern port of Turbo Vision 2.0", which is licensed under MIT licence

See: I<init_sys_error>, I<done_sys_error>

=over

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

L<drivers.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/drivers.pas>, 
L<win32con.cpp|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/source/platform/win32con.cpp>
