=pod

=head1 NAME

TurboVision::Drivers::Win32::SystemError - System Error Handler implementation

=cut

package TurboVision::Drivers::Win32::SystemError;

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

use TurboVision::Const qw( :bool );
use TurboVision::Drivers::Types qw( StdioCtl );
use TurboVision::Drivers::Win32::StdioCtl;

use Win32::Console;

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all

    :vars
      $sys_error_func
      $sys_color_attr
      $sys_mono_attr
      $save_ctrl_break
      $ctrl_break_hit
      $sys_err_active
      $fail_sys_errors
  
    :syserr
      init_sys_error
      done_sys_error
      system_error

=cut

use Exporter qw(import);

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  vars => [qw(
    $sys_error_func
    $sys_color_attr
    $sys_mono_attr
    $ctrl_break_hit
    $save_ctrl_break
    $sys_err_active
    $fail_sys_errors
  )],

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
# Variables --------------------------------------------------------------
# ------------------------------------------------------------------------
  
=head2 Variables

=over

=item public C<< CodeRef $sys_error_func >>

I<$sys_error_func> points to the system error handling sub routine.

You can override system error handling by writing your own sub and assigning it
to the I<$sys_error_func> variable.

The default system error handler is defined as,

  sub system_error(Int $error_code, Int $drive)

where I<$error_code> is a value from the table below, and <$drive> is the drive
number (A=1, B=1, C=3, and so on).

I<system_error> should return 0 if the user requests to retry the operation or 1
if the user elected to abort the function.

Table of System Error Codes

  Error code  Usage
  0           Disk is write protected
  1           Critical disk error
  2           Disk is not ready
  3           Critical disk error
  4           Data integrity error
  5           Critical disk error
  6           Seek error
  7           Unknown media type
  8           Sector not found
  9           Printer out of paper
  10          Write fault
  11          Read fault
  12          Hardware failure       
  13          Bad memory image of file allocation table
  14          Device access error
  15          Drive swap notification (floppy disks have changed)

Note: I<$error_code> corresponds to the system error codes 19 to 34 of MS-DOS or
Windows (I<$^E> or I<$EXTENDED_OS_ERROR>).

See: I<sys_color_attr>, I<sys_err_active>, I<sys_error_func>, I<sys_mono_attr>,
I<system_error>, I<TSysErrorFunc>, I<init_sys_error>.

=cut

  sub system_error;
  our $sys_error_func = \&system_error;

=item public C<< Int $sys_color_attr >>

On color displays, I<$sys_color_attr> (default value: 0x4e4f) specifies the
attribute bytes for system error messages. (I<$sys_mono_attr> specifies the
attribute bytes for monochrome).

System error messages are OS crtical errors (such as disk drive not accessible)
and other device type errors.

System errors are displayed on the status line in the color specified by the
second part of I<$sys_color_attr>, 0x4f, white on red text.

The first part, 0x4e, is used for highlighting command keys, such as Enter or
Esc.

See: I<system_error>, I<sys_mono_attr>.

=cut

  our $sys_color_attr = 0x4e4f;

=item public C<< Int $sys_mono_attr >>

On monochrome displays, I<$sys_mono_attr> (default value: 0x7070) specifies the
attribute bytes for system error messages. (I<sys_color_attr> specifies the
attribute bytes for color).

System error messages are OS crtical errors (such as disk drive not accessible)
and other device type errors.

See I<sys_color_attr> for more information about the attribute values.

See: I<system_error>, I<sys_color_attr>.

=cut

  our $sys_mono_attr = 0x7070;

=item public C<< Bool $ctrl_break_hit >>

Whenever the user presses Ctrl-Break at the keyboard, this flag is set to
I<TRUE>. 

You can clear it any time by resetting to <FALSE>.

=cut

  our $ctrl_break_hit = _FALSE;

=item public readonly C<< Bool $save_ctrl_break >>

This internal variable is set to the state of the OS Ctrl-break checking at
program initialization; at program termination, OS's Ctrl-break trapping is
restored to the value saved in I<$save_ctrl_break>.

See: I<init_sys_error>, I<done_sys_error>

=cut

  our $save_ctrl_break = _FALSE;

=item public readonly C<< Bool $sys_err_active >>

If True, then the system error handler is available for use.

=cut

  our $sys_err_active = _FALSE;

=item public C<< Bool $fail_sys_errors >>

If the variable is I<TRUE>, the routine for critical errors behaves as if the
user had pressed the Esc key when the error was displayed.

If I<FALSE>, an error message with a prompt is normally displayed on the bottom
line.

=cut

  our $fail_sys_errors = _FALSE;

=begin comment

=item local C<< Object $_io >>

STD ioctl object I<< StdioCtl->instance() >>

=end comment

=cut

  my $_io;
  INIT { $_io = StdioCtl->instance() }

=back

=cut

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutines

=over

=item public C<< init_sys_error() >>

This internal routine, called by I<< TApplication->init >>, initializes system
error trapping by redirecting the handling of I<Keyboard>, I<Ctrl-Break>,
I<System>, I<Ctrl-C> and I<Critical-Error>, and clearing Ctrl-Break state.

System error trapping is terminated by calling the corresponding
I<done_sys_error> routine.

=cut

  func init_sys_error() {
    my $CONSOLE = $_io->in();                           # get input console

    my $mode = $CONSOLE->Mode();                        # save Ctrl+C status
    $save_ctrl_break = !!( $mode & ENABLE_PROCESSED_INPUT );
    $mode &= ~ENABLE_PROCESSED_INPUT;                   # Report Ctrl+C and ...
    $CONSOLE->Mode( $mode );                            # ... Shift+Arrow events

    return;
  }

=item public C<< done_sys_error() >>

This internal routine is called automatically by I<< TApplication->DEMOLISH >>,
terminating Turbo Vision's system error trapping and restoring the handling of
I<Keyboard>, I<Ctrl-Break>, I<System>, I<Ctrl-C> and I<Critical-Error>, to their
original settings.

=cut

  func done_sys_error() {
    my $CONSOLE = $_io->in();                           # get input console

    my $mode = $CONSOLE->Mode();                        # restore Ctrl-C status
    $mode |= ENABLE_PROCESSED_INPUT if $save_ctrl_break;
    $CONSOLE->Mode( $mode );
    
    return;
  }

=item public C<< Int system_error(Int $error_code, Int $drive) >>

This function handles system errors (such as DOS critical errors). See
I<$sys_error_func> for details on the parameters and their values.

I<system_error> returns 0 if the user requests that the operation be retried,
and 1 if the user elects to cancel the operation.

See: I<$sys_error_func>

=cut

  func system_error(Int $error_code, Int $drive) {
    return 1                                          # Return 1 for ignored
        if $fail_sys_errors;                          # Check error ignore

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

 POD sections by Ed Mitchell are licensed under modified CC BY-NC-ND.

=head1 AUTHORS
 
=over

=item *

1996-2000 by Leon de Boer E<lt>ldeboer@attglobal.netE<gt>

=item *

1992 by Ed Mitchell (Turbo Pascal Reference electronic freeware book)

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
