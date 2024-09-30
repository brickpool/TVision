=pod

=head1 NAME

TurboVision::Views::Common - Variables and tools used by I<Views>

=head1 SYNOPSIS

  use TurboVision::Views::Common qw(
    :vars
  );
  ...

=cut

package TurboVision::Views::Common;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use constant::boolean;
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

use TurboVision::Objects::Point;
use TurboVision::Objects::Types qw( TPoint );
use TurboVision::Views::CommandSet;
use TurboVision::Views::Const qw( :cmXXXX );
use TurboVision::Views::Types qw( TCommandSet );

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all

    :vars
      $command_set_changed
      $cur_command_set
      $error_attr
      $shadow_attr
      $shadow_size

    :subs
      register_views

    private:
      $_fixup_list
      $_owner_group
      $_the_top_view

=cut

use Exporter qw(import);

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  vars => [qw(
    $command_set_changed
    $cur_command_set
    $error_attr
    $shadow_attr
    $shadow_size
  )],

  subs => [qw(
    register_views
  )],

  private => [qw(
    $_fixup_list
    $_owner_group
    $_the_top_view
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

=item I<$command_set_changed>

  our $command_set_changed = < Bool >;

True if the command set has changed since being set to false.

=cut

  our $command_set_changed = FALSE;

=item I<$cur_command_set>

  our $cur_command_set = < TCommandSet >;

I<$cur_command_set> is a command set object that uses bit vector arithmetic.

It stores the current command set. By default, all commands except those of the
window are active.

=cut

  our $cur_command_set = TCommandSet->new( cmds => pack( 'b*', 1 x 256 ) )
    - [CM_ZOOM, CM_CLOSE, CM_RESIZE, CM_NEXT, CM_PREV];   # All active but these


=item I<$error_attr>

  our $error_attr = < Int >;

Error colours.

=cut

  our $error_attr = 0xcf;

=item I<$shadow_attr>

  our $shadow_attr = < Int >;

Shadow attribute.

=cut

  our $shadow_attr =  0x08;

=item I<$shadow_size>

  our $shadow_size = < TPoint >;

Shadow sizes.

=cut

  our $shadow_size = TPoint->new(x => 2, y => 1);

=item I<$_fixup_list>

  our $_fixup_list = < TFixupList >;

Used for loading.

=cut

  our $_fixup_list;

=item I<$_owner_group>

  our $_owner_group = < TGroup >;

Used for loading.

=cut

  our $_owner_group;

=item I<$_the_top_view>

  our $_the_top_view = < TView >;

Top focused view.

=cut

  our $_the_top_view;

=back

=cut

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutines

=over

=item I<register_views>

  func register_views()

Calls I<register_type> for each of the class types defined in the I<Views>
module: I<TView>, I<TFrame>, I<TScrollBar>, I<TScroller>, I<TListViewer>, 
I<TGroup>, I<Window>.

=cut

  func register_views() {
    require TurboVision::Views::View;
    require TurboVision::Views::Group;

    TStreamRec->register_type(TView->RView);              # Register views
    TStreamRec->register_type(TGroup->RGroup);            # Register group
    
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

 POD sections by Ed Mitchell are licensed under modified CC BY-NC-ND.

=head1 AUTHORS

=over

=item *

1996-1999 by Leon de Boer E<lt>ldeboer@attglobal.netE<gt>

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

2023-2024 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

L<views.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/views.pas>
