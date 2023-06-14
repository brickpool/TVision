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

use Function::Parameters {
  func => {
    defaults    => 'function_strict',
  },
  factory => {
    defaults    => 'classmethod_strict',
    shift       => '$class',
    name        => 'required',
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

use TurboVision::Const qw( :bool );
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
  10    if ( $set_up_data->prog_options & 2 ) {
  11      $commands_off -= [CM_USE_DOS];
  12    }
  13    if ( $set_up_data->prog_options & 4 ) {
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

  has _cmds ( is => rw, type => Str );

Internal attribute to hold the bit vector.

=cut

  has '_cmds' => (
    is  => 'rw',
    isa => Str,
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => TCommandSet;

=head2 Constructors

=over

=item I<new>

  factory $class->new() : TCommandSet
  factory $class->new( TCommandSet $set ) : TCommandSet
  factory $class->new( ArrayRef[Int] $set ) : TCommandSet

The L<Moose::Object> method I<BUILDARGS> is overridden for a customized
(simple non-hash based) passing of parameters.

=cut

  around BUILDARGS(Undef|TCommandSet|ArrayRef[Int] $set=) {
    my $cmds = _EMPTY_SET;
    if ( is_TCommandSet $set ) {
      $cmds = $set->_cmds;
    }
    elsif ( is_ArrayRef $set ) {
      foreach my $cmd ( @$set ) {
        vec ($cmds, $cmd, 1) = 1
          if $cmd >= 0 && $cmd <= 255;
      }
    }
    return $self->$next( _cmds => $cmds );
  }

=back

=cut

  # ------------------------------------------------------------------------
  # TCommandSet ---------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item I<disable_cmd>

  method disable_cmd( Int $cmd )

The method clear the command <$cmd> into the given command set.

  method disable_cmd( TCommandSet $set )
  method disable_cmd( ArrayRef[Int] $set )

This methods insert all commands of I<$set> into the given command set.

=cut

  method disable_cmd(Int|TCommandSet|ArrayRef[Int] $set) {
    my $cmds = $self->_cmds;
    if ( is_Int $set ) {
      my $cmd = $set;
      vec ($cmds, $cmd, 1) = 0
        if $cmd >= 0 && $cmd <= 255;
    }
    elsif ( is_TCommandSet $set ) {
      $cmds &= ~$set->_cmds;
    }
    else { # is ArrayRef[Int]
      foreach my $cmd ( @$set ) {
        vec ($cmds, $cmd, 1) = 0
          if $cmd >= 0 && $cmd <= 255;
      }
    }
    $self->_cmds( $cmds );
    return;
  }

=item I<enable_cmd>

  method enable_cmd( Int $cmd )

The method puts the command <$cmd> into the given command set.

  method enable_cmd( TCommandSet $set )
  method enable_cmd( ArrayRef[Int] $set )

This methods insert all commands of I<$set> into the given command set.

=cut

  method enable_cmd(Int|TCommandSet|ArrayRef[Int] $set) {
    my $cmds = $self->_cmds;
    if ( is_Int $set ) {
      my $cmd = $set;
      vec ($cmds, $cmd, 1) = 1
        if $cmd >= 0 && $cmd <= 255;
    }
    elsif ( is_TCommandSet $set ) {
      $cmds |= $set->_cmds;
    }
    else { # is ArrayRef[Int]
      foreach my $cmd ( @$set ) {
        vec ($cmds, $cmd, 1) = 1
          if $cmd >= 0 && $cmd <= 255;
      }
    }
    $self->_cmds( $cmds );
    return;
  }

=item I<enabled>

  method enabled(Int $cmd) : Bool

Returns the current state of the command I<$cmd> in the command set, i.e.,
returns false if it is cleared (in the "off" state) or true if it is set
(in the "on" state).

=cut

  method enabled(Int $cmd) {
    return _FALSE
        if $cmd < 0 || $cmd > 255;
    return !! vec($self->_cmds, $cmd, 1)
  }

=item I<is_empty>

  method is_empty() : Bool

Tests whether the given bit vector is empty, i.e., whether ALL of its bits are
cleared (in the "off" state).

Returns true if the bit vector is empty and false otherwise.

=cut

  method is_empty() {
    return _EMPTY_SET eq $self->_cmds;
  }

=back

=head2 Overload Methods

=over

=item I<_and>

  func _and(TCommandSet $set1, TCommandSet $set2) : TCommandSet

This sub routine calculates the intersection of I<$set1> and I<$set2> and
returns the result as a new commend set so that we can write code like
C<< $cmds = $set1 & $set2 >>.

See: L</_intersect>, L</_or>

=cut

  func _and(TCommandSet $set1, TCommandSet $set2, $=) {
    my $set = TCommandSet->new();
    $set->_cmds( $set1->_cmds & $set2->_cmds );
    return $set;
  };
  use overload '&' => '_and', fallback => 0;

=item I<_clone>

  method _clone() : TCommandSet

Overloading the copy constructor so that we can write code like
C<< $cmds = $set; $cmds += CM_QUIT; >> without affecting C<$set>.

=cut

  method _clone(@) {
    return TCommandSet->new( $self );
  };
  use overload '=' => '_clone', fallback => 0;

=item I<_disable>

  method _disable( Int $cmd ) : TCommandSet
  method _disable( TCommandSet $set ) : TCommandSet
  method _disable( ArrayRef[Int] $set ) : TCommandSet

This method disabled all commands of I<$set> in the given command set.

Used for overloading C<-=> assignment so that we can write code like
C<< $cmds -= $set >>.

See: L</disable_cmd>

=cut

  method _disable($set, $=) {
    $self->disable_cmd($set);
    return $self;
  };
  use overload '-=' => '_disable', fallback => 1;

=item I<_enable>

  method _enable( Int $cmd ) : TCommandSet
  method _enable( TCommandSet $set ) : TCommandSet
  method _enable( ArrayRef[Int] $set ) : TCommandSet

This method enabled all commands of I<$set> in the given command set.

Used for overloading C<+=> assignment so that we can write code like
C<< $cmds += $set >>.

See: L</enable_cmd>, L</_or>, L</_union>

=cut

  method _enable($set, $=) {
    $self->enable_cmd($set);
    return $self;
  };
  use overload '+=' => '_enable', fallback => 1;

=item I<_equal>

  func _equal(TCommandSet $set1, TCommandSet $set2) : Bool

Overload equal comparison C<==> so that we can write code like
C<< $set1 == $set2 >>.

See: L</_not_equal>

=cut

  func _equal(TCommandSet $set1, TCommandSet $set2, $=) {
    return $set1->_cmds eq $set2->_cmds;
  };
  use overload '==' => '_equal', fallback => 0;

=item I<_intersect>

  method _intersect( Int $cmd ) : TCommandSet
  method _intersect( TCommandSet $set ) : TCommandSet
  method _intersect( ArrayRef[Int] $set ) : TCommandSet

This method calculates the intersection of the I<$self> and I<$set> and stores
the result in I<$self> so that we can write code like C<< $cmds &= $set >>.

See: L</_and>, L</_union>

=cut

  method _intersect($set, $=) {
    $self->_cmds( $self->_cmds & TCommandSet->new($set)->_cmds );
    return $self;
  };
  use overload '&=' => '_intersect', fallback => 1;

=item I<_not_equal>

  func _not_equal(TCommandSet $set1, TCommandSet $two) : Bool

Overload not equal comparison C<!=> so that we can write code like
C<< $set1 != $set2 >>.

See: L</_equal>

=cut

  func _not_equal(TCommandSet $set1, TCommandSet $set2, $=) {
    return $set1->_cmds ne $set2->_cmds;
  };
  use overload '!=' => '_not_equal', fallback => 0;

=item I<_or>

  func _or(TCommandSet $set1, TCommandSet $set2) : TCommandSet

This sub routine calculates the union of I<$set1> and I<$set2> and returns the
result as a new commend set so that we can write code like
C<< $cmds = $set1 | $set2 >>.

See: L</_and>, L</_enable>, L</_union>

=cut

  func _or(TCommandSet $set1, TCommandSet $set2, $=) {
    my $set = TCommandSet->new();
    $set->_cmds( $set1->_cmds | $set2->_cmds );
    return $set;
  };
  use overload '|' => '_or', fallback => 0;

=item I<_union>

  method _union( Int $cmd ) : TCommandSet
  method _union( TCommandSet $set ) : TCommandSet
  method _union( ArrayRef[Int] $set ) : TCommandSet

This method calculates the union of the I<$self> and I<$set> and stores the
result in I<$self> so that we can write code like C<< $cmds |= $set >>.

See: L</_enable>, L</_or>

=cut

  func _union(@) {
    goto &_enable;
  };
  use overload '|=' => '_union', fallback => 1;

=back

=head2 Inheritance

Methods inherited from class L<Moose::Object>

  does, DOES, dump, DESTROY

=cut

}

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
