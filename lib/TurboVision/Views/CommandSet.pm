=pod

=head1 NAME

TurboVision::Views::CommandSet - Bit vector with a set of 256 bits

=cut

package TurboVision::Views::CommandSet;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use constant::boolean;
use Function::Parameters {
  func => {
    defaults    => 'function_strict',
  },
  factory => {
    defaults    => 'classmethod_strict',
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
our $AUTHORITY = 'github:magiblot';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on': 'off';
use MooseX::StrictConstructor;

use TurboVision::Views::Types qw( TCommandSet );

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

In Turbo Vision, command codes are assigned values from 0 to 65535, with values
in the range of 0 to 255 reserved for items that can be selectively disabled.

I<TCommandSet> is used to hold a set of up to 256 commands, specifically those
that can be disabled, and is used as a parameter for the I<TView> methods,
I<enable_commands>, I<disable_commands>, I<get_commands> and I<set_commands>.

Listing C<tcmdset.pl> illustrates the use of a I<TCommandSet> type.

   1  # tcmdset.pl
   2  # Example using TCommandSet, from TVSHELL8.PAS }
   3
   4    my $commands_on = TCommandSet->new();
   5    my $commands_off = TCommandSet->new();
   6    ...
   7    $commands_on += [CM_USE_DOS, CM_DELETE];
   8    $commands_off = $commands_on;
   9  
  10    if ( $tc_up_data->prog_options & 2 ) {
  11      $commands_off -= [CM_USE_DOS];
  12    }
  13    if ( $tc_up_data->prog_options & 4 ) {
  14      $commands_off -= [CM_DELETE];
  15    }
  16    $commands_on = $commands_on - $commands_off;
  17  
  18    $self->disable_commands( $commands_off );
  19    $self->enable_commands( $commands_on );

=head2 Class

public class I<< TCommandSet >>

Turbo Vision Hierarchy

  Moose::Object
    TCommandSet

=cut

package TurboVision::Views::CommandSet {
  
  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

=begin comment

=head2 Constants

=over

=item I<_EMPTY_SET>

  constant _EMPTY_SET = < Str >;

The constant I<_EMPTY_SET> is for the definition of a 265-bit vector of the Str
data type.

=end comment

=cut

  use constant _EMPTY_SET => pack('b*', 0 x 256);

=begin comment

=back

=end comment

=cut

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Attributes

=over

=item I<_cmds>

  has _cmds (
    is        => rw,
    type      => Bit::Vector::Str,
    init_arg  => 'cmds',
    coerce    => 1,
  ) = '';

Internal attribute to hold the bit vector string.

=cut

  has '_cmds' => (
    is        => 'rw',
    isa       => 'Bit::Vector::Str',
    init_arg  => 'cmds',
    coerce    => 1,
    default   => _EMPTY_SET,
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => __PACKAGE__;

=head2 Constructors

=over

=item I<init>

  factory init() : TCommandSet
  factory init(ArrayRef[Int] $tc) : TCommandSet

Calls the I<new> constructor, but uses a simple non-hash based passing of
commands.

=cut

  factory init(Undef|ArrayRef[Int] $tc=) {
    return defined $tc
          ? $class->new( cmds => $tc )
          : $class->new()
          ;
  }

=back

=cut

  # ------------------------------------------------------------------------
  # TCommandSet ---------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item I<contains>

  method contains(Int $cmd) : Bool

Check wether the command I<$cmd> is in the command set.

Returns false if the element is not in the command set, or true if it is.

=cut

  method contains(Int $cmd) {
    return FALSE
        if $cmd < 0 || $cmd > 255;
    assert( exists $$self{_cmds} );
    return vec($self->{_cmds}, $cmd, 1) == 1
  }

=item I<copy>

  method copy(TCommandSet $tc)

I<copy> sets the command set to the same commands as in I<$tc>.

=cut

  method copy(TCommandSet $tc) {
    $self->_cmds( $tc->_cmds );
    return;
  }

=item I<disable_cmd>

  method disable_cmd(Int $cmd)

The method clear the command <$cmd> into the given command set.

=cut

  method disable_cmd(Int $cmd) {
    if ( $cmd >= 0 && $cmd < 256 ) {
      assert( exists $$self{_cmds} );
      vec ($self->{_cmds}, $cmd, 1) = 0;
    }
    return;
  }

=item I<enable_cmd>

  method enable_cmd( Int $cmd )

The method puts the command <$cmd> into the given command set.

=cut

  method enable_cmd(Int $cmd) {
    if ( $cmd >= 0 && $cmd < 256 ) {
      assert( exists $$self{_cmds} );
      vec ($self->{_cmds}, $cmd, 1) = 1;
    }
    return;
  }

=item I<is_empty>

  method is_empty() : Bool

Tests whether the given command set is empty.

Returns true if the command set is empty and false otherwise.

=cut

  method is_empty() {
    return _EMPTY_SET eq $self->_cmds;
  }

=back

=head2 Overload Methods

The following operations on sets can be performed with operators: union,
difference, symmetric difference and intersection.

Elements can be added or removed from the set with the include or exclude
operators.

Furthermore, sets can be compared or checked if an element is included.

The supported operators for this are listed in the following table:

  Operator  Subroutine    Action
  =         _clone        copy constructor
  +         _union        union
  -         _difference   difference
  *         _intersection intersection
  +=        _include      include elements to the set
  -=        _exclude      exclude elements from the set
  ==        _equal        equal
  !=        _not_equal    not equal
  ~~        _matching     check whether an element is in the set

=over

=item I<_clone>

=item operator C<=>

  method _clone() : TCommandSet

Overloading the copy constructor so that we can write code like
C<< $tc2 = $tc1; $tc2 += CM_QUIT; >> without affecting C<$tc1>.

=cut

  method _clone(@) {
    my $this = TCommandSet->new();
    $this->copy( $self );
    return $this;
  };
  use overload '=' => '_clone', fallback => 0;

=item I<_difference>

=item operator C<->

  func _difference(TCommandSet $tc1, TCommandSet $tc2, Bool $swap) : TCommandSet
  func _difference(TCommandSet $tc1, ArrayRef[Int] $tc2, 
    Bool $swap) : TCommandSet

This method calculates the difference of I<$tc1> and I<$tc2> and returns the
result as a new commend set so that we can write code like
C<< $cmds = $tc1 - $tc2 >>.

=cut

  func _difference(TCommandSet $tc1, TCommandSet|ArrayRef[Int] $tc2, Bool $swap)
  {
    $tc2 = TCommandSet->new(cmds => $tc2)
      if is_ArrayRef $tc2;
    ( $tc2, $tc1 ) = ( $tc1, $tc2 ) if $swap;
    return TCommandSet->new(
      cmds => ( $tc1->_cmds & ~$tc2->_cmds )
    );
  };
  use overload '-' => '_difference';

=item I<_equal>

=item operator C<==>

  func _equal(TCommandSet $tc1, TCommandSet $tc2) : Bool
  func _equal(TCommandSet $tc1, ArrayRef[Int] $tc2) : Bool

Overload equal comparison C<==> so that we can write code like
C<< $tc1 == $tc2 >>.

B<See>: L</_not_equal>

=cut

  func _equal(TCommandSet $tc1, TCommandSet|ArrayRef[Int] $tc2, $=) {
    $tc2 = TCommandSet->new(cmds => $tc2)
      if is_ArrayRef $tc2;
    return $tc1->_cmds eq $tc2->_cmds;
  };
  use overload '==' => '_equal';

=item I<_exclude>

=item operator C<-=>

  method _exclude(ArrayRef[Int] $tc) : TCommandSet

Exclude an element from the set, so that we can write code like
C<< $cmds -= $cmd >>.

B<See>: L</disable_cmd>

=cut

  method _exclude(ArrayRef[Int] $tc, $=) {
    $self->disable_cmd($_)
      foreach @$tc;
    return $self;
  };
  use overload '-=' => '_exclude';

=cut

=item I<_include>

=item operator C<+=>

  method _include(ArrayRef[Int] $tc) : TCommandSet

Include an element in the set, so that we can write code like
C<< $cmds += $cmd >>.

B<See>: L</enable_cmd>

=cut

  method _include(ArrayRef[Int] $tc, $=) {
    $self->enable_cmd($_)
      foreach @$tc;
    return $self;
  };
  use overload '+=' => '_include';

=item I<_intersection>

=item operator C<*>

  func _intersection(TCommandSet $tc1, TCommandSet $tc2) : TCommandSet
  func _intersection(TCommandSet $tc1, ArrayRef[Int] $tc2) : TCommandSet

This sub routine calculates the intersection of I<$tc1> and I<$tc2> and returns
the result as a new commend set so that we can write code like
C<< $cmds = $tc1 * $tc2 >>.

B<See>: L</_union>

=cut

  func _intersection(TCommandSet $tc1, TCommandSet|ArrayRef[Int] $tc2, $=) {
    $tc2 = TCommandSet->new(cmds => $tc2)
      if is_ArrayRef $tc2;
    return TCommandSet->new(
      cmds => ($tc1->_cmds & $tc2->_cmds)
    );
  };
  use overload '*' => '_intersection';

=item I<_matching>

=item operator C<~~>

  method _matching(ArrayRef[Int] $tc) : Bool

The matching operation C<~~> results true if the left operand (a command list)
is included of the right operand (a command set), the result will be false
otherwise.

=cut

  method _matching(ArrayRef[Int] $tc, $=) {
    my $hits = grep { $self->contains($_) } @$tc;
    return $hits == scalar @$tc;
  };
  use overload '~~' => '_matching';

=item I<_not_equal>

=item operator C<!=>

  func _not_equal(TCommandSet $tc1, TCommandSet $tc2) : Bool
  func _not_equal(TCommandSet $tc1, ArrayRef[Int] $tc2) : Bool

Overload not equal comparison C<!=> so that we can write code like
C<< $tc1 != $tc2 >>.

B<See>: L</_equal>

=cut

  func _not_equal(TCommandSet $tc1, TCommandSet|ArrayRef[Int] $tc2, $=) {
    $tc2 = TCommandSet->new(cmds => $tc2)
      if is_ArrayRef $tc2;
    return $tc1->_cmds ne $tc2->_cmds;
  };
  use overload '!=' => '_not_equal';

=item I<_union>

=item operator C<+>

  func _union(TCommandSet $tc1, TCommandSet $tc2) : TCommandSet
  func _union(TCommandSet $tc1, ArrayRef[Int] $tc2) : TCommandSet

This method calculates the union of I<$tc1> and I<$tc2> and returns the result
as a new commend set so that we can write code like C<< $cmds = $tc1 + $tc2 >>.

B<See>: L</_intersection>, L</_include>

=cut

  func _union(TCommandSet $tc1, TCommandSet|ArrayRef[Int] $tc2, $=) {
    $tc2 = TCommandSet->new(cmds => $tc2)
      if is_ArrayRef $tc2;
    return TCommandSet->new(
      cmds => ($tc1->_cmds | $tc2->_cmds)
    );
  };
  use overload '+' => '_union';

=back

=head2 Inheritance

Methods inherited from class L<Moose::Object>

  does, DOES, dump, DESTROY

=cut

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Turbo Vision library.

 Copyright (c) 2019-2021 by magiblot

 This library content was taken from the framework
 "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.

=head1 AUTHORS

=over

=item *

1994 by Borland International

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

L<Moose::Object>, 
L<views.h|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/include/tvision/views.h>, 
L<tcmdset.cpp|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/source/tvision/tcmdset.cpp>
