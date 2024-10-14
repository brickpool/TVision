=pod

=head1 NAME

TGroup - manages groups of objects that are all derived from TView.

=head1 SYNOPSIS

See I<TApplication>, I<TDeskTop>, I<TDialog>, I<TWindow>

=cut

package TurboVision::Views::Group;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use constant::boolean;
use Function::Parameters {
  factory_inherit => {
    defaults    => 'method_strict',
    install_sub => 'around',
    shift       => ['$super', '$class'],
    runtime     => 1,
    name        => 'required',
  },
},
qw(
  method
);

use Moose;
use MooseX::Types::Moose qw( :all );
use MooseX::HasDefaults::RO;
use namespace::autoclean;

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:fpc';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use TurboVision::Objects::Common qw( fail );
use TurboVision::Objects::Rect;
use TurboVision::Objects::Stream;
use TurboVision::Objects::StreamRec;
use TurboVision::Objects::Types qw(
  TRect
  TStream
  TStreamRec
);
use TurboVision::Views::Common qw(
  :private
);
use TurboVision::Views::Const qw( 
  :ofXXXX
  :phXXXX
  :smXXXX
);
use TurboVision::Views::Types qw(
  TGroup
  Phase
  TView
  TVideoBuf
);
use TurboVision::Views::View;

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

use Moose::Exporter;
Moose::Exporter->setup_import_methods(
  as_is => [ 'RGroup' ],
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

The I<TGroup> object manages groups of objects, all of which are descended from 
I<TView>.

In effect, I<TGroup> keeps track of a group of subviews, such as multiple 
windows on the desktop, or all of the controls within a dialog. I<TGroup> 
provides the functionality to manipulate the grouped views as if they were a 
single view, although I<TGroup> itself, surprisingly, is an invisible view.

That's because each of the subviews contained within a group defines the group 
itself.

For example, a I<TDialog> contains a window, a frame, a dialog interior and a 
collection of controls such as input lines, checkboxes and buttons.

The I<TDialog> object is the manager of these dialog box components and is 
actually invisible.

When I<< TDialog->draw >> is called to draw itself on the screen, it doesn't 
actually draw anything; instead, I<< TDialog->draw >> calls each of the 
subview's L</draw> methods (the window, the frame, the buttons and so on).

B<Commonly Used Features>

For most applications you will use only a few of the methods provided by
I<TGroup>, including the L</init> constructor (via the subview's inherited 
I<init> methods), L</exec_view> to execute a modal dialog box, L</insert> to add
a subview to the group, and L</get_data> and L</set_data> to read and write the 
data fields of the owned views (particularly for dialogs).

I<TGroup> is an internal object used to support other Turbo Vision objects (such
as I<TWindow> or I<TDialog>), and the remaining methods are used to implement 
their specific functionality.

It is unlikely that you will need to instantiate a I<TGroup> directly.

=head2 Class

public class I<< TGroup >>

Turbo Vision Hierarchy.

  TObject
    TView
      TGroup

=cut

package TurboVision::Views::Group {

  extends TView->class();

  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Constants

=over

=item I<RGroup>

  constant RGroup = < TStreamRec >;

Defining a registration record constant for I<TGroup>.

I<TGroup> is registered with I<< TStreamRec->register_type(RGroup) >>.

=cut

  use constant RGroup => TStreamRec->new(
    obj_type  => 6,                                       # Register id = 6
    vmt_link  => __PACKAGE__,                             # Object link
    load      => 'load',                                  # Object load method
    store     => 'store',                                 # Object store method
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Attributes

=over

=item I<buffer>

  has buffer ( is => ro, type => TVideoBuf );

When caching of views is in effect, the contents of the group of views is
stored in a temporary cache buffer to speed up screen redrawing.  

The field I<buffer> points to the memory buffer used for caching, or is C<undef>
if no cache buffer has been defined.

B<See>: I<get_buf_mem>, I<< TGroup->draw >>, I<< TGroup->lock >>, 
I<< TGroup->unlock >>

=cut

  has 'buffer' => (
    isa     => TVideoBuf,
  );

=item I<current>

  field current ( is => rwp, type => TView, weak_ref => 1 );

Is a reference to the currently selected view (the view whose I<select> method
has been called). 

B<See>: I<< TView->select >>

=cut

  has 'current' => (
    isa       => TView,
    init_arg  => undef,
    writer    => '_current',
    weak_ref  => 1,
  );

=item I<last>

  field last ( is => rwp, type => TView, weak_ref => 1 );

The I<last> field store a reference to the subview that is on the bottom of the 
Z-ordered list of views.

Each view contains a I<< TView->next >> reference that stores the next view in 
the list.

=cut

  has 'last' => (
    isa       => TView,
    init_arg  => undef,
    writer    => '_last',
    weak_ref  => 1,
  );

=item I<phase>

  has phase ( is => rwp, type => Phase ) = PH_FOCUSED;

Subviews can examine this field to determine at which phase in the event
processing their I<handle_event> method was called. 

=cut

  has 'phase' => (
    isa     => Phase,
    writer  => '_phase',
    default => PH_FOCUSED,
  );

=begin comment

=item I<_clip>

  has _clip ( is => private, type => TRect ) = TRect->new();

=cut

  has '_clip' => (
    isa     => TRect,
    default => sub { TRect->new() },
  );

=end comment

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => __PACKAGE__;

=head2 Constructors

=over

=item I<init>

  factory init(TRect $bounds) : TGroup

I<TGroup>'s I<init> method calls I<< TView->init >>, and sets the 
I<< TView->options >> variable to I<OF_SELECTABLE> and I<OF_BUFFERED>.

The latter option enables cache buffering of the view's I<draw> output, if 
sufficient memory is available.  

I<TView>'s I<event_mask> field is set to C<0xffff> which causes this view (or 
group) to respond to all classes of events.

=cut

  factory_inherit init(TRect $bounds) {
    my $self = $class->$super($bounds);                   # Call ancestor
	  $self->options( $self->options                        # Set options
      || ( OF_SELECTABLE + OF_BUFFERED ) );
	  $self->get_extent( $self->_clip );                    # Get clip extents
	  $self->event_mask( 0xffff );                          # See all events
    return $self;
  }

=item I<load>

  factory load(TStream $s)

Load creates a new I<TGroup> object and reads each subview from stream I<$s>.

=cut

  factory_inherit load(TStream $s) {
    my $read = sub {
      my $type = shift;
      SWITCH: for( $type ) {
        /word/ and do {
          $s->read(my $buf, word->size);
          return word( $buf )->unpack;
        };
      };
      return undef;
    };

    eval {
      my $self = $class->$super($s);                      # Call ancestor
  	  $self->get_extent( $self->_clip );                  # Get clip extents
      my $owner_save = $_owner_group;                     # Save current group
      $_owner_group = $self;                              # We are current group
      my $fixup_save = [ @$_fixup_list ];                 # Save current list
      my $count = 'word'->$read;                          # Read entry count
      my $v;
      $_fixup_list = [ (\undef) x $count ];               # Preset list entries
      for my $i ( 1 .. $count ) {
        $v = $s->get();                                   # Get view off stream
        $self->insert_view($v, undef)                     # Insert valid views
          if defined $v;
      }
      $v = $self->last;                                   # Start on last view
		  my ( $p, $q );
      for my $i ( 1 .. $count ) {
        $v = $v->next;                                    # Fetch next view
        $p = $_fixup_list->[$i];                          # Transfer reference
        while ( defined $p) {                             # If valid view
          $q = $p;                                        # Copy reference
          $p = $$p;                                       # Deref reference
          $$q = $v;                                       # Transfer view ref
        }
      }
      $_fixup_list = undef;                               # Delete fixup list
      $_owner_group = $owner_save;                        # Reload current group
      $_fixup_list = [ @$fixup_save ];                    # Reload current list
      $self->get_sub_view_ptr($s, $v);                    # Load any subviews
      $self->set_current($v, NORMAL_SELECT);              # Select current view
      $self->awaken 
        unless defined $_owner_group;                     # If topview activate
    } or do {
      return fail;
    }
  };

=back

=cut

  # ------------------------------------------------------------------------
  # Destructors ------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Destructors

=over

=item I<DEMOLISH>

  method DEMOLISH()

The method I<DEMOLISH> destroy the group and its contents.

I<DEMOLISH> first hides the group and then removes the link to and between the 
subviews. The views are destroyed as soon as the last reference to them 
disappears.

=cut

  method DEMOLISH(@) {
    $self->hide();                                        # Hide the view
    my $p = $self->last;                                  # Start on last
    if ( $p ) {                                           # Subviews exist
      do {
        $p->hide;                                         # Hide each view
        $p = $p->prev();                                  # Prior view
      } while ( $p != $self->last );                      # Loop complete
      do {{
        my $t = $p->prev();                               # Hold prior reference
        $p->_next( undef );                               # Remove next (ref)
        $p = $t;                                          # Transfer reference
      }} while ( $self->last );                           # Loop complete
    }
    return;
  }

=back

=cut

  # ------------------------------------------------------------------------
  # Public Methods ---------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Methods

=over

=item I<change_bounds>

  method change_bounds(TRect $bounds)

A group is resized or moved by calling I<change_bounds>, which, in turn, calls
I<< TView->calc_bounds >> to recalculate new boundaries for its subviews, and 
then I<change_bounds> to reposition the subviews.

These calls are made for every subview in the group.

=cut

  method change_bounds(TRect $bounds) {
    my $d = TPoint->new();

    my $do_calc_change = sub {
      my $p = $_[0];
      $p->calc_bounds(my $r, $d);                         # Calc view bounds
      $p->change_bounds($r);                              # Change view bounds
      return;
    };

    $d->x( $bounds->b->x - $bounds->a->x - $self->size->x );    # Delta x value
    $d->y( $bounds->b->y - $bounds->a->y - $self->size->y );    # Delta y value
    if ( $d->x == 0 && $d->y == 0 ) {
      $self->set_bounds($bounds);                         # Set new bounds
      # Force redraw
      $self->re_draw();                                   # Draw the view
    } 
    else {
      $self->set_bounds($bounds);                         # Set new bounds
      $self->get_extent($self->_clip);                    # Get new clip extents
      $self->lock;                                        # Lock drawing
		  $self->for_each( $do_calc_change );                 # Change each view
      $self->unLock;                                      # Unlock drawing
    }
    return;
  }

=item I<store>

  method store(TStream $s)

Outputs all the I<TGroup> and all of its subviews to stream I<$s>.

=cut

  method store(TStream $s) {
    ...
  }

=cut

=head2 Inheritance

Methods inherited from class L<TView>

  init

Methods inherited from class L<Moose::Object>

  new, BUILDARGS, does, DOES, dump, DESTROY

=cut
  
}

__PACKAGE__->meta->make_immutable;

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

I<TView>, 
L<views.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/views.pas>
