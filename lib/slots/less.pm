package slots::less;
# ABSTRACT: A simple pragma for managing slots of a UNIVERSAL::Object class.

use strict;
use warnings;
no strict 'refs';
no warnings 'once';

our $VERSION   = '0.07';
our $AUTHORITY = 'cpan:BRICKPOOL';

use autodie::Scope::Guard ();
use Carp                  ();

BEGIN { sub XS () { eval q[ use Class::XSAccessor ]; !$@ } }

BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }

sub import {
  shift;    # me
  my $caller = caller( 0 );

  # define the allowed option keys for the list-style form
  my %allowed = map { $_ => 1 } qw( is default );

  # assign 'slots' to %HAS and create accessors if necessary
  while ( @_ ) {
    my $name = shift;

    # basic sanity check for the slot name
    Carp::croak( "Slot name must be a plain string" )
      unless defined $name and !ref $name;

    Carp::croak( "No specification provided for slot '$name'" )
      unless @_;

    my $value = shift;

    # default case: simple form: 
    #   name => sub { ... }
    if ( ref $value eq 'CODE' ) {
      add_fields( $caller, $name => $value );
      next;
    }

    # extended case: list-style form:
    #   name => ( is => 'rw', default => sub { ... } )
    my %opts;
    my $key = $value;

    while ( 1 ) {
      # key must be a simple string and a known option
      Carp::croak("Invalid option name '$key' for slot '$name'")
        if ref $key || !$allowed{$key};

      Carp::croak("Missing value for option '$key' in slot '$name'")
        unless @_;

      $opts{$key} = shift;

      # stop if there are no more args
      # or if the next token is not a valid option key
      last if !@_ || ref($_[0]) || !$allowed{ $_[0] };

      # consume next option key
      $key = shift;
    }

    # defaults & validation
    $opts{is} //= 'rw';

    unless ( $opts{is} =~ /^ro|rw|bare$/ ) {
      Carp::croak( "Invalid value for 'is' in slot '$name': " .
        "expected 'rw', 'ro' or 'bare'" );
    }

    if ( exists $opts{default} && ref $opts{default} ne 'CODE' ) {
      Carp::croak( "Invalid 'default' for slot '$name': " .
        "expected a CODE reference" );
    }

    add_fields( $caller, $name => $opts{default} );
    add_accessor( $caller, $name => $opts{is} );
  } #/ while ( @args )

  # inherit parent %slots to callers %HAS at end of scope
  return if $^H{ __PACKAGE__ . "/$caller" };
  $^H{ __PACKAGE__ . "/$caller" } = autodie::Scope::Guard->new(sub {
	  inherit_fields( $caller );
  });
} #/ sub import

sub unimport {
  my $caller = caller();
  return unless $^H{ __PACKAGE__ . "/$caller" };
  $^H{ __PACKAGE__ . "/$caller" } = 0;
}

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

  # %HAS should only be inherited if UNIVERSAL::Object does exist
  return unless $class->isa( 'UNIVERSAL::Object' );

  # Retrieve the reference (automatic creation of an empty %HAS if necessary)
  my $HAS = get_fields( $class );

  # copy all superclass entries to %HAS
  my $superclasses = sub { shift; \@_ }
    ->( @{ mro::get_linear_isa( $class ) } );
  my %entries = ();
  %entries = ( %entries, %{ get_fields( $_ ) } ) 
    for grep { has_fields( $_ ) } reverse @$superclasses;
  %$HAS = ( %entries, %$HAS );

  return;
} #/ sub inherit_fields

# Adds a bunch of C<%slots> to the given C<$class>. For example:
#  # Add the slots 'this' and 'that' to the class 'Foo'.
#  require slots::less;
#  slots::less::add_fields( 'Foo', this => sub{ 'foo' }, that => sub { 'bar' });
sub add_fields {    # void ($class, %slots)
  my ( $class, %slots ) = @_;
  $class = ref $class if ref $class;

  # store key/value in %HAS
  my $HAS = get_fields( $class );
  foreach my $field ( keys %slots ) {
    $HAS->{$field} = ref $slots{$field} eq 'CODE' 
                   ? $slots{$field} 
                   : eval 'sub { }';
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
    Class::XSAccessor->import(
      class => $class,
      $mutator => { $field => $field },
    );
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

1;

__END__

=pod

=head1 NAME

slots::less - A simple pragma for UNIVERSAL::Object without MOP dependency

=head1 VERSION

version 0.07

=head1 DESCRIPTION

L<UNIVERSAL::Object> is a wonderful base class. The author I<Stevan Little> has 
added the pragma L<slots> for practical use, which is based on the L<MOP> 
distribution. In my opinion, this combination made the usage not as 
I<light-footed> as it could be. 

This is why this pragma was developed, which does not require the L<MOP> 
distribution.

Similar to the L<fields> pragma, C<slot::less> declares individual fields 
(stored in a global variable %HAS). L<UNIVERSAL::Object> is used as the base 
class, and access methods can be created using an 
L</extended list form|Extended List Form>.

This module also recognizes the superclasses of a class and ensures that their 
fields are inherited correctly. Inheritance occurs automatically at the end of 
the respective compilation scope in which the module is used. This is triggered 
by a scope guard registered via the hint hash.

=head2 Simple Form

The simple form with C<< name => sub { ... } >> was adopted from pragma 
L<slots>. The simple form associates a slot name with a CODE reference that
returns the default value:

  use slots (
    x => sub { 0 },
    y => sub { [] },
  );

In this form, the slot does not automatically creates a read/write accessor.

=head2 Extended List Form

An extended, Moose-like list form: C<< name => ( key => value, ... )>>,
allowing additional slot options such as read/write accessors and custom 
default generators.

  use slots (
    x => ( is => 'rw', default => sub { 1 } ),
    y => ( is => 'ro', default => sub { 2 } ),
  );

The extended form always begins with the slot name, followed by an odd-length 
list of option/value pairs. Supported options are:

=over 4

=item C<is>

Specifies the accessor type. Allowed values are C<'ro'>, C<'rw'> and C<'bare'>.
If omitted, C<'rw'> is assumed. When available, L<Class::XSAccessor> is used to 
generate the class accessors. 

=item C<default>

A CODE reference that generates the default value for the slot.

=back

=head1 DEPENDENCIES

L<autodie::Scope::Guard>, L<Carp>, L<UNIVERSAL::Object> and L<MRO::Compat> when 
using perl < v5.10.

=head1 LIMITATIONS

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

Copyright (c) 2024-2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
