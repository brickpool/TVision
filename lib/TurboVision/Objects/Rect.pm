=pod

=head1 NAME

TRect - Defines two coordinates of a rectangle.

=head1 SYNOPSIS

  use TurboVision::Objects;
  
  my $bounds = TRect->new();
  my $a_rectangle;
  ...
  # Initialize to the coordinates (0,0) and (80,2)
  $bounds->assign(0, 0, 80, 2);
  ...
  # Copy the contents of $bounds to $a_rectangle
  $a_rectangle->copy( $bounds );

=cut

package TurboVision::Objects::Rect;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use Function::Parameters {
  factory => {
    defaults    => 'classmethod_strict',
    name        => 'required',
  },
  func => {
    defaults    => 'function_strict',
  },
  around => {
    defaults    => 'method_strict',
    install_sub => 'around',
    shift       => ['$next', '$self'],
    runtime     => 1,
    name        => 'required',
  },
},
qw(
  classmethod
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

use Carp;

use TurboVision::Objects::Point;
use TurboVision::Objects::Types qw(
  is_TPoint
  TPoint
  TRect
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<TRect> is a simple object representing a rectangle on the screen.

I<TRect> primarly defines two coordinates, L</a> and L</b>, which are the upper
left and the lower right corners of a rectangle. I<TRect> parameters are used
throughout Turbo Vision to specify the screen location and size of windows,
dialog boxes and entry fields.

=head2 Class

public class I<< TRect >>

I<TRect> is a standalone object.

=cut

package TurboVision::Objects::Rect {

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Attributes

=over

=item I<a>

  has a ( is => rw, type => TPoint ) = TPoint->new;

I<a> is the point defining the top left corner of a rectangle on the screen.

=cut

  has 'a' => (
    is      => 'rw',
    isa     => TPoint,
    default => sub { TPoint->new() },
  );
  around a(Maybe[TPoint] $value=) {
    goto SET if @_;
    GET: {
      return $self->$next();
    }
    SET: {
      confess unless defined $value;
      return $self->$next(
        TPoint->new(
          x => $value->x,
          y => $value->y,
        )
      )
    }
  }
  
=item I<b>

  has b ( is => rw, type => TPoint ) = TPoint->new;

I<b> is the point defining the bottom right corner of a rectangle on the screen.

=cut

  has 'b' => (
    is      => 'rw',
    isa     => TPoint,
    default => sub { TPoint->new() },
  );
  around b(Maybe[TPoint] $value=) {
    goto SET if @_;
    GET: {
      return $self->$next();
    }
    SET: {
      confess unless defined $value;
      return $self->$next(
        TPoint->new(
          x => $value->x,
          y => $value->y,
        )
      )
    }
  }

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => __PACKAGE__;

=head2 Constructors

=over

=item I<init>

  factory init(Int $ax, Int $ay, Int $bx, Int $by) : TRect

Public constructor

=cut

  factory init(Int $ax, Int $ay, Int $bx, Int $by) {
    return $class->new(
      a => TPoint->new(x => $ax, y => $ay),
      b => TPoint->new(x => $bx, y => $by),
    );
  };

=back

=cut

  # ------------------------------------------------------------------------
  # TRect ------------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=head3 Object Methods

=over

=item I<assign>

  method assign(Int $ax, Int $ay, Int $bx, Int $by)

Assigns the parameter values to the rectangle's point attributes. I<$ax> becomes
I<< a->x >>, I<$bx> becomes I<< b->x >>, and so on.

=cut

  method assign(Int $ax, Int $ay, Int $bx, Int $by) {
    $self->a->x( $ax );
    $self->a->y( $ay );
    $self->b->x( $bx );
    $self->b->y( $by );
    return;
  };

=item I<contains>

  method contains(TPoint $p) : Bool 

Returns true if the rectangle contains the point I<$p>.

=cut

  method contains(TPoint $p) {
    return (
          $p->x >= $self->a->x
      &&  $p->x <  $self->b->x
      &&  $p->y >= $self->a->y
      &&  $p->y <  $self->b->y
    );
  };

=item I<copy>

  method copy(TRect $r)

I<copy> sets all attributes equal to those in rectangle I<$r>.

=cut

  method copy(TRect $r) {
    $self->a( $r->a );
    $self->b( $r->b );
    return;
  };

=item I<empty>

  method empty() : Bool

Returns true if the rectangle is empty

=cut

  method empty() {
    return (
          $self->a->x >= $self->b->x
      ||  $self->a->y >= $self->b->y
    );
  };

=item I<equals>

  method equals(TRect $r) : Bool

Returns true if I<$r> is the same as the rectangle.

=cut

  method equals(TRect $r) {
    return (
          $self->a->x == $r->a->x
      &&  $self->a->y == $r->a->y
      &&  $self->b->x == $r->b->x
      &&  $self->b->y == $r->b->y
    );
  };

=item I<grow>

  method grow(Int $a_dx, Int $a_dy)

Changes the size of the rectangle by subtracting I<$a_dx> from I<< a->x >>,
adding I<$a_dx> to I<< b->x >>, subtracting I<$a_dy> from I<< a->y >>, and
adding I<$a_dy> to I<< b->y >>.

=cut

  method grow(Int $a_dx, Int $a_dy) {
    $self->a->{x} -= $a_dx;
    $self->a->{y} -= $a_dy;
    $self->b->{x} += $a_dx;
    $self->b->{y} += $a_dy;
    TRect->_check_empty($self);
    return;
  };

=item I<intersect>

  method intersect(TRect $r)

Changes the location and size of the rectangle to the region defined by the
intersection of the current location and that of I<$r>.

=cut

  method intersect(TRect $r) {
    $self->a->x( $r->a->x ) if $r->a->x > $self->a->x;
    $self->a->y( $r->a->y ) if $r->a->y > $self->a->y;
    $self->b->x( $r->b->x ) if $r->b->x > $self->b->x;
    $self->b->y( $r->b->y ) if $r->b->y > $self->b->y;
    TRect->_check_empty($self);
    return;
  };

=item I<move>

  method move(Int $a_dx, Int $a_dy)

Moves the rectangle by adding I<$a_dx> to I<< a->x >> and I<< b->x >> and adding
I<$a_dy> to I<< a->y >> and I<< b->y >>.

=cut

  method move(Int $a_dx, Int $a_dy) {
    $self->a->{x} += $a_dx;
    $self->a->{y} += $a_dy;
    $self->b->{x} += $a_dx;
    $self->b->{y} += $a_dy;
    return;
  }

=item I<union>

  method union(TRect $r)

Changes the rectangle to be the union of itself and the rectangle I<$r>.

=cut

  method union(TRect $r) {
    $self->a->x( $r->a->x ) if $r->a->x < $self->a->x;
    $self->a->y( $r->a->y ) if $r->a->y < $self->a->y;
    $self->b->x( $r->a->x ) if $r->a->x > $self->b->x;
    $self->b->y( $r->b->y ) if $r->b->y > $self->b->y;
    return;
  };

=begin comment

=item I<_check_empty>

  classmethod _check_empty(TRect $r)

Sets the values of the point I<a> and I<b> to zero if the rectangle is empty.

=end comment

=cut

  classmethod _check_empty(TRect $r) {
    if ( $r->a->x >= $r->b->x || $r->a->y >= $r->b->y ) {
      $r->a->x( 0 );
      $r->a->y( 0 );
      $r->b->x( 0 );
      $r->b->y( 0 );
    }
    return;
  };

=back

=head3 Overload Methods

=over

=item I<_equal>

=item operator C<==>

  func _equal(TRect $one, TRect $two) : Bool

Overload equal comparison C<==> so we can write code like C<< $one == $two >>.

=cut

  func _equal(TRect $one, TRect $two, $=) {
    return $one->a == $two->a && $one->b == $two->b;
  };
  use overload '==' => '_equal';

=item I<_not_equal>

=item operator C<!=>

  func _not_equal(TRect $one, TRect $two) : Bool

Overload not equal comparison C<!=> so we can write code like
C<< $one != $two >>.

=cut

  func _not_equal(TRect $one, TRect $two, $=) {
    return $one->a != $two->a || $one->b != $two->b;
  };
  use overload '!=' => '_not_equal';

=item I<_stringify>

=item operator C<"">

  method _stringify() : Str

Overload stringify so we can write code like C<< print $rect >>.

=cut

  method _stringify(@) {
    return sprintf(
      "r->a->x : %d\nr->a->y : %d\nr->b->x : %d\nr->b->y : %d",
      $self->a->x, $self->a->y, $self->b->x, $self->b->y
    );
  };
  use overload '""' => '_stringify', fallback => 1;

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

I<TPoint>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
