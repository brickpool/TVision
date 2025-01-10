package TV::toolkit::LOP;
# ABSTRACT: The Lightweight Object Protocol for Turbo Vision objects

use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:BRICKPOOL';

use Module::Loaded;    # also loads 'base'
require base;          # .. but that could change in the future

# Code snippet taken from File::Spec
my %module; BEGIN { %module = (
  fields              => 'Class::Fields',
  # 'Class::LOP'        => 'Class::LOP',
  # 'Class::Tiny'       => 'Class::Tiny',
  # Moo                 => 'Moo',
  # Moose               => 'Moose',
  'UNIVERSAL::Object' => 'UNIVERSAL::Object'
)}

our $name; BEGIN {
  *name = \$TV::toolkit::name;
  foreach my $toolkit ( reverse sort keys %module ) {
    if ( Module::Loaded::is_loaded $toolkit ) {
      $name = $toolkit;
      last;
    }
  }
}

my $module = $module{$name} || 'Class::Fields';

require ''. base::_module_to_filename( 
  $name eq 'Class::LOP' 
    ? 'Class::LOP'
    : "TV::toolkit::LOP::$module" 
);

our @ISA = ( "${module}::LOP" );

1

__END__

=pod

=head1 NAME

TV::toolkit::LOP - The Lightweight Object Protocol for Turbo Vision objects

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This package was developed to support the interface provided by L<Class::LOP>. 
For this purpose, we use the different existing L<Class::LOP> implementations 
internally.

This is a derived class of L<Class::LOP>, which means that we inherit the 
interface of the base class and L<Class::LOP>.

=head1 METHODS

These explanations should help you to understand how to use these methods. If 
you still have questions or need further help, you should have a look at the 
L<Class::LOP> documentation.

=head2 new

  my $self = $self->new($class);

This constructor initializes a class, but creates a new class if it does not yet
exist. If you want to initialize a class that you know exists, it is better to 
use L</init>, as this requires less work. 

So with L</new> you can create a class and a method I<on-the-fly>. For example:

  TV::toolkit::LOP->new( 'MyNewClass' )
    ->create_method( 'foo', sub { print "foo!\n" } );
  my $class = MyNewClass->new();
  $class->foo();    # prints "foo!"

=head2 class_exists

  my $bool = $self->class_exists( | $class);

This method checks if a given class is already defined in your Perl environment. 
It returns a boolean value indicating whether the class exists or not. For 
example:

  my $class = TV::toolkit::LOP->new( 'SomeClass' );
  if ( $class->class_exists( 'SomeClass' ) ) {
    print "Class SomeClass exists!\n";
  }
  else {
    print "Class SomeClass does not exist.\n";
  }

=head2 clone_object

  my $clone | undef = $self->clone_object();

This method takes an existing object and creates an exact copy of it. The cloned
object will have the same properties and methods as the original object. This 
can be useful when you need to duplicate an object without affecting the 
original instance. For example:

  my $class = TV::toolkit::LOP->new( 'MyClass' );
  $class->create_method( 'foo', sub { return 'foo'; } );
  my $obj   = MyClass->new();
  my $clone = $class->clone_object( $obj );
  print $clone->foo();    # prints "foo"

=head2 create_class

  my $self = $self->create_class($class);

This method is used to create a new class. It initializes the class and allows 
you to add methods and properties. It is a more comprehensive method that 
defines the entire structure of the class. For example:

  my $class = TV::toolkit::LOP->new( 'MyClass' );
  $class->create_class( 'MyClass' )
    ->create_method( 'foo', sub { return 'foo'; } )
  my $obj = MyClass->new();
  print $obj->foo();     # prints "foo"

=head2 create_constructor

  my $self = $self->create_constructor();

This method simply adds the new method to your class, which acts as a 
constructor. It is a more specific method that only creates the constructor 
without adding additional methods or properties. For example:

  my $class = TV::toolkit::LOP->init( 'MyClass' );
  $class->create_constructor();
  my $obj = MyClass->new();
  print( 'Object created with constructor' ) if defined( $obj );

Differences in Application:

=over

=item *
L</create_class> is used when you want to create a new class from scratch, 
including defining the constructor and properties.

=item *
L</create_constructor> is used when you only want to add the constructor to a 
existing class.

=back

=head2 create_method

  my $self | undef = $self->create_method($name, $code);

This method adds a new method to an existing class. It allows you to define a 
subroutine that can be called on objects of the class. For example:

  my $class = TV::toolkit::LOP->new( 'MyClass' );
  $class->create_method( 'foo', sub { return 'foo'; } );
  my $obj = MyClass->new();
  print $obj->foo();    # prints "foo"

=head2 delete_method

  my \&code | undef = delete_method($name);

This method removes an existing method from a class. It is useful when you need 
to dynamically remove methods that are no longer needed. For example:

  my $class = TV::toolkit::LOP->new('MyClass');
  $class->create_method('foo', sub { return 'foo'; });
  $class->delete_method('foo');

=head2 extend_class

  my $self | undef = $self->extend_class(@mothers);

This method is used to extend a class with one or more parent classes. It is 
similar to using C<use parent> in Perl, allowing you to inherit methods and 
properties from the specified parent classes. For example:

  my $parent_class = TV::toolkit::LOP->new( 'ParentClass' );
  $parent_class->create_method( 'foo', sub { return 'foo'; } );
  my $child_class = TV::toolkit::LOP->new( 'ChildClass' );
  $child_class->extend_class( 'ParentClass' );
  my $obj = ChildClass->new();
  print $obj->foo();    # prints "foo"

=head2 get_attributes

  my \%attr = $self->get_attributes();

This method retrieves the attributes of a class. It returns a hash of 
attributes, with the key being the names of the attributes defined for this 
class. This can be useful for introspection or debugging purposes. For example:

  package MyClass;
  my $class = TV::toolkit::LOP->new( 'MyClass' );
  $class->have_accessors( 'slot' );
  slot name => ( is => 'rw' );
  slot age  => ( is => 'rw' );
  my @attributes = sort keys %{ $class->get_attributes() };
  print join( ", ", @attributes );    # prints "age, name"

=head2 have_accessors

  my $self | undef = $self->have_accessors($name);

This method adds L<Moose>-style accessors to a class. It allows you to define 
getter and setter methods for class attributes. The parameter is the name of 
the keyword to create accessors.

  package Toolkit;
  TV::toolkit::LOP->new( 'MyClass' )->have_accessors( 'acc' );
  ...
  package MyClass;
  use Toolkit;
  acc foo => ( is => 'ro', default => sub { 'foo' } );
  ...
  package main;
  use MyClass;
  my $obj = MyClass->new();
  print $obj->foo();    # prints "foo"

There are currently only two options that are supported: L</is> and L</default>:

=head3 is

C<is> currently only supports the three values C<'ro'>, C<'rw'> and C<'bare'>. 
The default value for C<is> is C<'rw'>.

=head3 default

C<default> can be a scalar or a reference to a subroutine. If C<default> is not 
specified, the value is undefined.

=head2 import_methods

  my $self | undef = $self->import_methods($class, @methods);

This method injects existing methods from one class into another specified 
class. It allows you to reuse methods across different classes. For example:

  my $class = TV::toolkit::LOP->new( 'ParentClass' );
  $class->create_method( 'foo', sub { return 'foo'; } );
  my $subclass = TV::toolkit::LOP->new( 'ChildClass' );
  $subclass->import_methods( 'ParentClass', 'foo' );
  my $obj = ChildClass->new();
  print $obj->foo();    # prints "foo"

=head2 init

  my $self = $self->init($class);

This constructor initializes a class. However, it does not create a new class, 
but sets the current class to the specified one, if it exists. You can then 
attach other methods to this method or save it in a variable in order to use it 
repeatedly. For example:

  TV::toolkit::LOP->init( 'SomeClass' );

=head2 list_methods

  my @methods = $self->list_methods();

This method returns a list of all the methods within an initialized class. It 
helps in introspection by listing all available methods. For example:

  my $class = TV::toolkit::LOP->new( 'MyClass' );
  $class->create_method( 'foo', sub { return 'foo'; } );
  my @methods = $class->list_methods();
  print join( ", ", @methods );    # prints "foo"

=head2 method_exists

  my $bool = $self->method_exists( | $class, $method);

This method checks if a specific method exists in a class. It returns a boolean 
value indicating whether the method is defined. For example:

  my $class = TV::toolkit::LOP->new( 'MyClass' );
  $class->create_method( 'foo', sub { return 'foo'; } );
  if ( $class->method_exists( 'foo' ) ) {
    print "Method foo exists\n";
  }
  else {
    print "Method foo does not exist\n";
  }

=head2 override_method

  my $self | undef = $self->override_method($name, $method);

This method allows you to replace an existing method in a class with a new 
implementation. It is useful for modifying the behavior of inherited methods. 
For example:

  my $class = TV::toolkit::LOP->new( 'MyClass' );
  $class->create_method( 'foo', sub { return 'foo'; } );
  my $obj = MyClass->new();
  print $obj->foo();    # prints "foo"
  $class->override_method( 'foo', sub { return 'bar'; } );
  print $obj->foo();    # prints "bar"

=head2 subclasses

  my @list = $self->subclasses();

This method returns a list of all subclasses that inherit from the specified 
class. It allows you to identify which classes are derived from a particular 
base class. For example:

  my $class = TV::toolkit::LOP->new( 'ParentClass' );
  my $subclass = TV::toolkit::LOP->new( 'ChildClass' );
  $subclass->extend_class( 'ParentClass' );
  my @subclasses = $class->subclasses();
  print join( ", ", @subclasses );    # prints "ChildClass"

=head2 superclasses

  my @list = $self->superclasses();

This method returns a list of all superclasses (base classes) from which the 
specified class inherits. It allows you to trace the inheritance hierarchy of a 
class. For example:

  my $parent_class = TV::toolkit::LOP->new( 'ParentClass' );
  my $child_class  = TV::toolkit::LOP->new( 'ChildClass' );
  $child_class->extend_class( 'ParentClass' );
  my @superclasses = $child_class->superclasses();
  print join( ", ", @superclasses );    # prints "ParentClass"

=head1 REQUIRES

L<base>

L<Module::Loaded>

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 CONTRIBUTORS

Brad Haywood <brad@perlpowered.com>

=head1 LICENSE

Copyright (c) 2024-2025 the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
