=pod

=head1 NAME

TPoint - Defines a point on the screen.

=head1 SYNOPSIS

  use TurboVision::Objects;
  
  # Defines the minimum size of a window object
  my $min_win_size = TPoint->new(x => 16, y => 6);

=cut

package TurboVision::Objects::Point;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use Function::Parameters {
  func => {
    defaults    => 'function_strict',
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

use MooseX::StrictConstructor;

use TurboVision::Objects::Types qw( TPoint );

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<TPoint> is a simple object representing a point on the screen.

=head2 Class

public class I<< TPoint >>

I<TPoint> is a standalone object.

=cut

package TurboVision::Objects::Point {

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Attributes

=over

=item I<x>

  has x ( is => rw, type => Int ) = 0;

I<x> is the screen column of the point.

=cut

  has 'x' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
  );

=item I<y>

  has y ( is => rw, type => Int ) = 0;

I<y> is the screen row of the point.

=cut

  has 'y' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => TPoint;

  # ------------------------------------------------------------------------
  # TPoint -----------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=item I<copy>

  method copy(TPoint $pt)

I<copy> sets all attributes equal to those in point I<$pt>.

=cut

  method copy(TPoint $pt) {
    $self->x( $pt->x );
    $self->y( $pt->y );
    return;
  }

=back

=head2 Overload Methods

=over

=item I<_add>

  func _add(TPoint $one, TPoint|Int $two, Bool $swap) : TPoint

Overload addition so that we can write code like C<< $pt = $one + $two >>.

=cut

  func _add(TPoint $one, TPoint|Int $two, $=) {
    return
      TPoint->new(
        x => $one->x + (is_Int($two) ? $two : $two->x),
        y => $one->y + (is_Int($two) ? $two : $two->y),
      );
  };
  use overload '+' => '_add', fallback => 1;

=item I<_clone>

  method _clone() : TPoint

Overloading the copy constructor so that we can write code like
C<< $c = $pt; $c++; >> without affecting C<$pt>.

=cut

  method _clone(@) {
    return
      TPoint->new(
          x => $self->x,
          y => $self->y,
        );
  };
  use overload '=' => '_clone', fallback => 0;

=item I<_decr>

  method _decr()

Overloading decrement so that we can write code like C<< $pt-- >>.

=cut

  method _decr(@) {
    $self->x( $self->x - 1 );
    $self->y( $self->y - 1 );
    return;
  };
  use overload '--' => '_decr', fallback => 1;

=item I<_equal>

  func _equal(TPoint $one, TPoint $two) : Bool

Overload equal comparison C<==> so that we can write code like C<< $one == $two >>.

=cut

  func _equal(TPoint $one, TPoint $two, $=) {
    return $one->x == $two->x && $one->y == $two->y;
  };
  use overload '==' => '_equal', fallback => 1;

=item I<_incr>

  method _incr()

Overloading increment so that we can write code like C<< $pt++ >>.

=cut

  method _incr(@) {
    $self->x( $self->x + 1 );
    $self->y( $self->y + 1 );
    return;
  };
  use overload '++' => '_incr', fallback => 1;

=item I<_not_equal>

  func _not_equal(TPoint $one, TPoint $two) : Bool

Overload not equal comparison C<!=> so that we can write code like
C<< $one != $two >>.

=cut

  func _not_equal(TPoint $one, TPoint $two, $=) {
    return $one->x != $two->x || $one->y != $two->y;
  };
  use overload '!=' => '_not_equal', fallback => 1;

=item I<_stringify>

  method _stringify() : Str

Overload stringify so that we can write code like C<< print $pt >>.

=cut

  method _stringify(@) {
    return sprintf(
      "p->x : %d\np->y : %d", $self->x, $self->y
    );
  };
  use overload '""' => '_stringify', fallback => 1;

=item I<_sub>

  func _sub(TPoint $one, TPoint|Int $two, Bool $swap) : TPoint

Overload subtraction so that we can write code like C<< $pt = $one - $two >>.

=cut

  func _sub(TPoint $one, TPoint|Int $two, Bool $swap) {
    return
      $swap ? TPoint->new(
                x => (is_Int($two) ? $two : $two->x) - $one->x,
                y => (is_Int($two) ? $two : $two->x) - $one->y,
              )
            : TPoint->new(
                x => $one->x - (is_Int($two) ? $two : $two->x),
                y => $one->y - (is_Int($two) ? $two : $two->y),
              )
            ;
  };
  use overload '-' => '_sub', fallback => 1;

=back

=head2 Inheritance

Methods inherited from class L<Moose::Object>

  new, BUILDARGS, does, DOES, dump, DESTROY

=cut
  
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Free Pascal run time library.
 Copyright (c) 1999-2000 by the Free Pascal development team.

 Interface Copyright (c) 1992 Borland International

 The run-time files are licensed under modified LGPL.

 The creation of subclasses of this LGPL-licensed class is considered to be
 using an interface of a library, in analogy to a function call of a library.
 It is not considered a modification of the original class. Therefore,
 subclasses created in this way are not subject to the obligations that an LGPL
 imposes on licensees.

 POD sections by Ed Mitchell are licensed under modified CC BY-NC-ND.

=head1 AUTHORS

=over

=item *

1999-2000 by Florian Klaempfl E<lt>fnklaemp@cip.ft.uni-erlangen.deE<gt>

=item *

1999-2000 by Frank ZAGO E<lt>zago@ecoledoc.ipc.frE<gt>

=item *

1999-2000 by MH Spiegel

=item *

1996, 1999-2000 by Leon de Boer E<lt>ldeboer@ibm.netE<gt>

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

I<TRect>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
