package slots::less;
# ABSTRACT: A simple pragma for managing slots of a UNIVERSAL::Object class.

use strict;
use warnings;
no strict 'refs';
no warnings 'once';

our $VERSION   = '0.05';
our $AUTHORITY = 'cpan:BRICKPOOL';

use Carp ();

BEGIN { sub XS () { eval q[ use Class::XSAccessor ]; !$@ } }

BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }

sub import {
  shift;    # me
  my $caller = caller( 0 );

  # Only if UNIVERSAL::Object was used as the base class
  if ( $caller->isa( 'UNIVERSAL::Object' ) ) {

    # initialize %HAS variable
    inherit_fields( $caller );

    # assign 'slots' to %HAS and create the accessors
    if ( @_ ) {
      my %slots = @_;
      add_fields( $caller, %slots );
      add_accessor( $caller, $_ ) for keys %slots;
    }
  } #/ if ( $caller->isa( 'UNIVERSAL::Object'...))

  $^H{'slots::less/%HAS'} = 1;
} #/ sub import

# A simple check to see if the given C<$class> has a C<%HAS> hash defined. A 
# simple test like C<defined %{"${class}::HAS"}> will sometimes produce typo 
# warnings because it would create the hash if it was not present before.
sub has_fields {    # $bool ($class)
  my $class = shift;
  $class = ref $class if ref $class;
  my $fglob = *{"${class}::HAS"}{HASH};
  return defined $fglob;
}

# Gets a reference to the C<%HAS> hash for the given C<$class>. It will 
# autogenerate a C<%HAS> hash if one doesn't already exist. If you don't want 
# this behavior, be sure to check beforehand with L</has_fields>.
sub get_fields {    # \%HAS ($class)
  my $class = shift;
  $class = ref $class if ref $class;

  # avoid possible typo warnings
  %{"${class}::HAS"} = () unless %{"${class}::HAS"};
  return \%{"${class}::HAS"};
}

# The C<$class> will inherit all of the base class's slots. This is similar to 
# what happens to C<%FIELDS> when you use L<base.pm|base>.
sub inherit_fields {    # void ($class)
  my $class = shift;
  $class = ref $class if ref $class;

  # %HAS should only be inherited if %HAS does not exist
  return if has_fields( $class );

  # Retrieve the reference (automatic creation of an empty %HAS if necessary)
  my $HAS = get_fields( $class );

  # copy all superclass entries to %HAS
  my $superclasses = sub { shift; \@_ }
    ->( @{ mro::get_linear_isa( $class ) } );
  %$HAS = ( %$HAS, %{ get_fields( $_ ) } ) 
    for grep { has_fields( $_ ) } reverse @$superclasses;

  return;
} #/ sub inherit_fields

# Adds a bunch of C<%slots> to the given C<$class>. For example:
#  # Add the slots 'this' and 'that' to the class 'Foo'.
#  require slot::less;
#  slot::less::add_fields( 'Foo', this => sub{ 'foo' }, that => sub { 'bar' } );
sub add_fields {    # void ($class, %slots)
  my ( $class, %slots ) = @_;
  $class = ref $class if ref $class;

  # Only create fields if %HAS exists
  return unless has_fields( $class );

  # store key/value in %HAS
  my $HAS = get_fields( $class );
  foreach my $field ( keys %slots ) {
    $HAS->{$field} = ref $slots{$field} eq 'CODE' ? $slots{$field} : sub { }
  }

  return;
} #/ sub add_fields

# If you want to create a new accessor, use the L</add_accessor> class method. 
# It ensures that a read/write accessor sub is created (if not already present; 
# C<unless __PACKAGE__->can($field)>). C<$access> is an optional parameter that
# supports the values C<'ro'>, C<'rw'> and C<'bare'>. If not specified, the 
# C<'rw'> access is used.
sub add_accessor {    # void ($class, $field, | $access)
  my ( $class, $field, $access ) = @_;
  $class = ref $class if ref $class;
  $access ||= 'rw';

  # Only create accessors unless is 'bare'
  return if $access eq 'bare';

  # Only create accessors unless exists
  return if $class->can( $field );

  # create the accessor and use the XS version if available
  if ( XS ) {
    my $mutator = $access eq 'ro' ? 'getters' : 'accessors';
    eval qq[
      use Class::XSAccessor
        class => '$class',
        $mutator => { '$field' => '$field' };
      return 1;
    ] or Carp::croak( "Can't create accessor in class '$class': $@" );
  }
  else {
    my $acc = "${class}::${field}";
    unless ( exists &$acc ) {
      *$acc = $access eq 'ro'
            ? sub {
                $#_
                  ? Carp::croak( "Usage: ${class}::${field}(self)" )
                  : $_[0]->{$field};
              }
            : sub {
                $#_
                  ? $_[0]->{$field} = $_[1]
                  : $_[0]->{$field};
              }
    } #/ unless ( exists &$acc )
  } #/ else [ if ( XS ) ]

  return;
} #/ sub add_accessor

sub unimport {
  $^H{'slots::less/%HAS'} = 0;
}

1;

__END__

=pod

=head1 NAME

slots::less - A simple pragma for UNIVERSAL::Object without MOP dependency

=head1 VERSION

version 0.05

=head1 DESCRIPTION

L<UNIVERSAL::Object> is a wonderful base class. The author I<Stevan Little> has 
added the pragma L<slots> for practical use, which is based on the L<MOP> 
distribution. In my opinion, this combination made the usage not as 
I<light-footed> as originally started. 

This is why this pragma was developed, which does not require the L<MOP> 
distribution.

Similar to the L<fields> pragma, C<slot::less> declares individual fields 
(stored in a global variable %HAS) and create accessors if a class based 
L<UNIVERSAL::Object> is in use.

When available, L<Class::XSAccessor> is used to generate the class accessors.

=head1 DEPENDENCIES

L<Carp>, L<UNIVERSAL::Object> and L<MRO::Compat> when using perl < v5.10.

=head1 BUGS, CAVETS

This pragma creates the global variable C<%HAS> used by C<UNIVERSAL::Objects>. 
This means that all derived classes will require C<%HAS> (including inherited 
entries), even if no new I<slots> are added. 

The simplest way to achieve this is by consistently using C<use slots::less;>. 
The import routine creates the global variable C<%HAS> and initializes the 
necessary entries.

=head1 SEE ALSO

L<fields>, L<slots>.

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 CONTRIBUTORS

Stevan Little <stevan@cpan.org>

Michael G Schwern <schwern@pobox.com>

=head1 LICENSE

Copyright (c) 2024 the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
