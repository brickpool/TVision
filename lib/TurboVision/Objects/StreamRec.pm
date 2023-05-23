=pod

=head1 NAME

TStreamRec - Stream record structure for I<TStream>

=head1 SYNOPSIS

  package SomeObject;

  use Moose;
  use Moose::Exporter;
  Moose::Exporter->setup_import_methods(
    as_is => [ 'RSomeObject' ],
  );
  
  use constant RSomeObject => TStreamRec->new(
    obj_type  => 1050,
    vmt_link  => __PACKAGE__,
    load      => 'load',
    store     => 'store',
  );
  ...
  
  sub load {
    ...
  }

  sub store {
    ...
  }
  ...

=cut

package TurboVision::Objects::StreamRec;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use Function::Parameters qw(
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

use MooseX::ClassAttribute;
use MooseX::StrictConstructor;
use MooseX::Types::Perl qw( Identifier );

use TurboVision::Objects::Types qw(
  TStreamRec
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

A Turbo Vision class type must have a registered I<TStreamRec> before its
objects can be loaded or stored on a I<TStream> object.

The I<TStreamRec> record I<type> is used in registering objects prior to storing
to or loading from a I<TStream>. You register an object for stream I/O by
initializing the attributes of the I<TStreamRec> and then passing the record as
a parameter to the I<register_type> procedure.

When you define your own variables as I<TStreamRec> I<types>, it is recommended
that you begin each registration record variable name with the letter I<R> as
an aid to identifying registration records. Turbo Vision predefines registration
records for all of its objects, each beginning with an C<R> instead of a C<T>.
For example, I<TCollection>'s registration record is I<RCollection>.

=cut

=head2 Class

public class I<< TStreamRec >>

=cut

package TurboVision::Objects::StreamRec {

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Attributes

=head3 Class Attributes

=over

=item private static C<< TStreamRec _stream_types >>

=back

=cut

  class_has '_stream_types' => (
    is        => 'rw',
    isa       => TStreamRec,
    predicate => '_has_stream_types',
    clearer   => '_clear_stream_types',
  );

=head3 Attributes

=over

=item public readonly C<< Int obj_type >>

I<obj_type> is a unique number from 1,000 to 65,535 that you choose to
identify your object.

=cut

  has 'obj_type' => (
    isa       => Int,
    required  => 1,
  );

=item public readonly C<< ClassName vmt_link >>

I<vmt_link> is an internal link to the object's virtual method table. 

In Pascal, you would set this attribute equal to C<Ofs(TypeOf(TSomeObject)^)>
where I<TSomeObject> is any object type, but in Perl we use the package class
name C<__PACKAGE__>.

=cut

  has 'vmt_link' => (
    isa       => ClassName,
    required  => 1,
  );

=item public readonly C<< Str load >>

Class load code name to the I<load> constructor.

=cut

  has 'load' => (
    isa       => Identifier,
    predicate => 'has_load',
  );

=item public readonly C<< Str store >>

Class store code name to the I<store> method.

=cut

  has 'store' => (
    isa       => Identifier,
    predicate => 'has_store',
  );

=item public readonly C<< TStreamRec next >>

I<next> is a reference to the next I<TStreamRec>. You do not need to initialize
this value.

=cut

  has 'next' => (
    isa       => TStreamRec,
    predicate => 'has_next',
    writer    => '_next',
  );

=back

=cut

  # ------------------------------------------------------------------------
  # TStreamRec -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Class Methods

Stream interface routines

=over

=item private static C<< _register_error() >>

Register error when an invalid type is registered.

B<Note>: Private internal routine.

=cut

  classmethod _register_error() {
    confess 'Stream registration error';
    return;
  }

=item public static C<< register_type(TStreamRec $s) >>

Registers the given object type with Turbo Vision's streams, creating a list of
known classes. Streams can only store and return these known class types. Each
registered class needs a unique stream registration record, of type
I<TStreamRec>.

=cut

  classmethod register_type(TStreamRec $s) {
    my $p = $class->_has_stream_types                     # Current reg list
          ? $class->_stream_types
          : undef
          ;
    while ( $p && $p->obj_type != $s->obj_type ) {
      $p = $p->has_next                                   # Find end of chain
         ? $p->next
         : undef
         ;
    }
    if ( !defined $p && $s->obj_type ) {                  # Valid end found
      if ( $class->_has_stream_types ) {
        $s->_next( $class->_stream_types )                # Chain the list
      }
      $class->_stream_types($s);                          # We are now first
    }
    else {
      goto &_register_error();                            # Register the error
    }
    return;
  }

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

2021 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

L<Objects>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
