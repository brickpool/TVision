=pod

=head1 NAME

TurboVision::Drivers::Win32::Keyboard - Event Manager Keyboard implementation

=cut

package TurboVision::Drivers::Win32::Keyboard;

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

use Data::Alias qw( alias );
use PerlX::Assert;

use TurboVision::Drivers::Const qw( :evXXXX );
use TurboVision::Drivers::Event;
use TurboVision::Drivers::Types qw(
  TEvent
  is_TEvent
);
use TurboVision::Drivers::Win32::EventManager qw( :private );

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all
  
    :kbd
      get_key_event
      get_shift_state

=cut

use Exporter qw(import);

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  kbd => [qw(
    get_key_event
    get_shift_state
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
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutines

=over

=item public static C<< get_key_event(TEvent $event) >>

Emulates the BIOS function INT 16h, Function 01h "Read LowLevel Status" to
determine if a key has been pressed on the keyboard.

If so, I<< $event->what >> is set to I<EV_KEY_DOWN> and I<< $event->key_code >>
is set to the scan code of the key.

If no keys have been pressed, I<< $event->what >> is set to I<EV_NOTHING>.

This is an internal procedure called by I<< TProgram->get_event >>.

See: I<evXXXX> constants

=cut

  func get_key_event($) {
    alias my $event = $_[-1];

    _update_event_queue();

    for (my $i = 0; $i < @_event_queue; $i++) {
      $event = $_event_queue[$i];
      assert { is_TEvent $event };

      if ( $event->what & EV_KEYBOARD ) {
        splice(@_event_queue, $i, 1);
        return;
      }
    }

    $event = TEvent->new();
    return;
  }

=item public static C<< Int get_shift_state() >>

Returns a integer (octal) containing the current Shift key state. The return
value contains a combination of the I<kbXXXX> constants for shift states.

=cut

  func get_shift_state() {
    return $_shift_state;
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

2021-2023 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

L<drivers.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/drivers.pas>, 
