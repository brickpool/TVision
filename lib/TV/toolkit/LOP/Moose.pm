package Moose::LOP;
# ABSTRACT: A Lightweight Object Protocol for Moose.

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:BRICKPOOL';

require Carp;
use Moose;
use Moose::Meta::Class ();
use Moose::Util qw( find_meta );

with 'Moose::Class::LOP::Role';

has _name       => ( is => 'ro', required => 1 );
has classes     => ( is => 'bare', default => sub { [] } );
has _attributes => ( is => 'bare', default => sub { {} } );

sub BUILD {    # $self (@)
  my ( $self ) = @_;
  $self->create_constructor()
    unless $self->class_exists( $self->name );
  return;
}

around BUILDARGS => sub {    # $self ($class)
  my $next = shift;
  my $self = shift;
  return @_ == 1 && !ref $_[0]
    ? $self->$next( _name => $_[0] )
    : $self->$next( @_ );
};

sub init {    # $self ($class)
  my ( $self, $class ) = @_;
  return ref $self
    ? $self
    : $self->SUPER::new( $class );
};

sub class_exists {    # $bool (| $class)
  my ( $self, $class ) = @_;
  $class ||= $self->name;
  return !!find_meta( $class );
};

around list_methods => sub {    # @methods ()
  my ( $next, $self ) = @_;
  if ( my $meta = find_meta( $self->name ) ) {
    return $meta->get_all_method_names();
  }
  return $self->$next();
};

around method_exists => sub {    # $bool (| $class, $method)
  my $next   = shift;
  my $self   = shift;
  my $class  = @_ > 1 ? shift : $self->name;
  my $method = shift;
  if ( my $meta = find_meta( $class ) ) {
    return $meta->has_method( $method );
  }
  return $self->$next( $class, $method );
};

around subclasses => sub {    # @list ()
  my ( $next, $self ) = @_;
  if ( my $meta = find_meta( $self->name ) ) {
    return $meta->subclasses();
  }
  return $self->$next();
};

around superclasses => sub {    # @list ()
  my ( $next, $self ) = @_;
  if ( my $meta = find_meta( $self->name ) ) {
    return $meta->superclasses();
  }
  return $self->$next();
};

around import_methods => sub {    # $self|undef ($class, @methods)
  my ( $next, $self, $class, @methods ) = @_;
  my $caller = $self->name;
  my $meta = find_meta( $caller );
  my $target = find_meta( $class );
  if ( $meta && $target ) {
    foreach my $name ( @methods ) {
      my $method = $meta->get_method( $name );
      unless ( ref $method ) {
        Carp::carp "Cannot read method $name, it does not exist in $caller.";
        next;
      } 
      $target->add_method( $name, $method );
    }
    return $self;
  }
  return $self->$next( $class, @methods );
}; #/ sub import_methods

around extend_class => sub {    # $self|undef (@mothers)
  my $next = shift;
  my $self = shift;
  if ( my $meta = find_meta( $self->name ) ) {
    $meta->superclasses( @_ );
    return $self;
  }
  return $self->$next( @_ );
};

sub have_accessors {    # $self|undef ($name)
  my ( $self, $name ) = @_;
  my $class = $self->name;
  if ( $self->class_exists( $class ) ) {
    no strict 'refs';

    # Create the slot
    my $slot = "${class}::${name}";
    *$slot = sub {
      my ( $attr, %args ) = @_;

      # Prepare attributes
      my $value = do {
        my $d = delete $args{default};
        my $r = ref $d;
        $r eq 'HASH'  ? sub { +{%$d} } :
        $r eq 'ARRAY' ? sub { [@$d] }  :
        $r eq 'CODE'  ? $d             :
                        sub { $d }     ;
      };
      my $access = delete $args{is} || 'rw';

      # Add attribute and create the accessor incl. default handling
      $self->_add_attribute( $class, $attr, $value );
      find_meta( $class )
        ->add_attribute( $attr => ( is => $access, default => $value ) );

      return;
    }; #/ *$slot = sub

    return $self;
  } #/ if ( $self->class_exists...)
  Carp::carp(
    "Can't create accessors in class '$class', because it doesn't exist" );
  return;
}; #/ have_accessors => sub

sub create_constructor {    # $self|undef ()
  my ( $self ) = @_;
  my $class = $self->name;
  return $self 
    if !$self->class_exists( $class )
    && Moose::Meta::Class->create( $class, superclasses => ['Moose::Object'] );
  return;
}; #/ create_constructor => sub

sub create_class {    # $bool ($class)
  my ( $self, $class ) = @_;
  if ( $self->class_exists( $self->name ) ) {
    Carp::carp( "Can't create class '$class'. Already exists" );
    return;
  }
  return !$self->class_exists( $class )
  && Moose::Meta::Class->create( $class, superclasses => ['Moose::Object'] );
}; #/ create_class => sub

around create_method => sub {    # $self|undef ($name, $code)
  my ( $next, $self, $name, $code ) = @_;
  my $class = $self->name;
  if ( my $meta = find_meta( $class ) ) {
    $meta->add_method( $name, $code );
    return $self;
  }
  return $self->$next( $name, $code );
};

around override_method => sub {    # $self|undef ($name, $method)
  my ( $next, $self, $name, $method ) = @_;
  my $class = $self->name;
  unless ( $self->method_exists( $class, $name ) ) {
    Carp::carp "Cant't find '$name' in class $class - override_method()";
    return;
  }
  if ( my $meta = find_meta( $class ) ) {
    $meta->add_method( $name, $method );
    return $self;
  }
  return $self->$next( $name, $method );
};

around clone_object => sub {    # $clone|undef ()
  my ( $next, $self ) = @_;
  my $class = $self->name;
  if ( my $meta = find_meta( $class ) ) {
    unless ( ref $class ) {
      Carp::carp "clone_object() expects a reference";
      return;
    }
    return $meta->clone_object( $class );
  }
  return $self->$next();
};

around delete_method => sub {    # \&code|undef ($name)
  my ( $next, $self, $name ) = @_;
  if ( my $meta = find_meta( $self->name ) ) {
    my $method = $meta->remove_method( $name );
    return ref $method ? $method->body() : undef;
  }
  return $self->$next( $name );
};

around get_attributes => sub {    # \%attr ()
  my ( $next, $self ) = @_;
  if ( my $meta = find_meta( $self->name ) ) {
    my %attr = map {
      $_ => $meta->get_attribute( $_ )->default()
    } $meta->get_attribute_list();
    return \%attr;
  }
  return $self->$next();
};

__PACKAGE__->meta->make_immutable;

1;

BEGIN {
  package Moose::Class::LOP::Role;
  use Moose::Role;
  use Class::LOP;

  requires 'new';
  requires 'init';

  my %remove = map { $_ => 1 } qw(
    __ANON__
    BEGIN
    import
    init
    new
    VERSION
  );
  my @methods = grep { not $remove{$_} }
    Class::LOP->init( 'Class::LOP' )->list_methods();

  foreach my $name ( @methods ) {
    my $body = do {
      no strict 'refs';
      *{"Class::LOP::${name}"}{CODE};
    } || next;
    __PACKAGE__->meta->add_method( $name, $body );
  }

  $INC{"Moose/Class/LOP/Role.pm"} = 1;
}

__END__

=pod

=head1 NAME

Moose::LOP - The Lightweight Object Protocol for Moose

=head1 VERSION

version 0.01

=head1 DESCRIPTION

L<Moose> is an extension of the Perl 5 object system, which is based on the 
L<Class::MOP> distribution. 

This package was developed to support the interface provided by L<Class::LOP>. 
For this purpose, we use the L<Class::MOP> distribution internally.

=head1 METHODS

This is a derived class of L<Moose::Object|Moose> using L<Class::LOP> as role, 
which means that we inherit the interface of the L<Moose::Object|Moose> base 
class, use the methods of L<Class::LOP> via L<Moose::Role> and extend them 
accordingly.

The following methods of the methods imported as a role of L<Class::LOP> have 
been overwritten:

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

  Moose::LOP->new( 'MyNewClass' )
    ->create_method( 'foo', sub { print "foo!\n" } );
  my $class = MyNewClass->new();
  $class->foo();    # prints "foo!"

=head2 class_exists

  my $bool = $self->class_exists( | $class);

This method checks if a given class is already defined in your Perl environment. 
It returns a boolean value indicating whether the class exists or not. For 
example:

  my $class = Moose::LOP->new( 'SomeClass' );
  if ( $class->class_exists( 'SomeClass' ) ) {
    print "Class SomeClass exists!\n";
  }
  else {
    print "Class SomeClass does not exist.\n";
  }

B<Note:> This method is based on C<Moose::Util::find_meta>.

=head2 clone_object

  my $clone | undef = $self->clone_object();

This method takes an existing object and creates an exact copy of it. The cloned
object will have the same properties and methods as the original object. This 
can be useful when you need to duplicate an object without affecting the 
original instance. For example:

  my $class = Moose::LOP->new( 'MyClass' );
  $class->create_method( 'foo', sub { return 'foo'; } );
  my $obj   = MyClass->new();
  my $clone = $class->clone_object( $obj );
  print $clone->foo();    # prints "foo"

B<Note:> This method is based on C<< Class::MOP::Class->clone_object >>.

=head2 create_class

  my $self = $self->create_class($class);

This method is used to create a new class. It initializes the class and allows 
you to add methods and properties. It is a more comprehensive method that 
defines the entire structure of the class. For example:

  my $class = Moose::LOP->new( 'MyClass' );
  $class->create_class( 'MyClass' )
    ->create_method( 'foo', sub { return 'foo'; } )
  my $obj = MyClass->new();
  print $obj->foo();     # prints "foo"

B<Note:> This constructor is based on C<< Moose::Meta::Class->create >>.

=head2 create_constructor

  my $self = $self->create_constructor();

This method simply adds the new method to your class, which acts as a 
constructor. It is a more specific method that only creates the constructor 
without adding additional methods or properties. For example:

  my $class = Moose::LOP->init( 'MyClass' );
  $class->create_constructor();
  my $obj = MyClass->new();
  print( 'Object created with constructor' ) if defined( $obj );

B<Note:> This constructor is based on C<< Moose::Meta::Class->create >>.

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

  my $class = Moose::LOP->new( 'MyClass' );
  $class->create_method( 'foo', sub { return 'foo'; } );
  my $obj = MyClass->new();
  print $obj->foo();    # prints "foo"

B<Note:> This method is based on C<< Class::MOP::Class->add_method >>.

=head2 delete_method

  my \&code | undef = delete_method($name);

This method removes an existing method from a class. It is useful when you need 
to dynamically remove methods that are no longer needed. For example:

  my $class = Moose::LOP->new('MyClass');
  $class->create_method('foo', sub { return 'foo'; });
  $class->delete_method('foo');

B<Note:> This method is based on C<< Class::MOP::Class->remove_method >> and 
C<< Class::MOP::Method->body >>.

=head2 extend_class

  my $self | undef = $self->extend_class(@mothers);

This method is used to extend a class with one or more parent classes. It is 
similar to using C<use parent> in Perl, allowing you to inherit methods and 
properties from the specified parent classes. For example:

  my $parent_class = Moose::LOP->new( 'ParentClass' );
  $parent_class->create_method( 'foo', sub { return 'foo'; } );
  my $child_class = Moose::LOP->new( 'ChildClass' );
  $child_class->extend_class( 'ParentClass' );
  my $obj = ChildClass->new();
  print $obj->foo();    # prints "foo"

B<Note:> This method is based on C<< Class::MOP::Class->superclasses >>.

=head2 get_attributes

  my \%attr = $self->get_attributes();

This method retrieves the attributes of a class. It returns a hash of 
attributes, with the key being the names of the attributes defined for this 
class. This can be useful for introspection or debugging purposes. For example:

  package MyClass;
  my $class = Moose::LOP->new( 'MyClass' );
  $class->have_accessors( 'slot' );
  slot name => ( is => 'rw' );
  slot age  => ( is => 'rw' );
  my @attributes = sort keys %{ $class->get_attributes() };
  print join( ", ", @attributes );    # prints "age, name"

B<Note:> This method is based on C<< Class::MOP::Class->get_attribute >> and 
C<< Class::MOP::Attribute->default >>.

=head2 have_accessors

  my $self | undef = $self->have_accessors($name);

This method adds L<Moose>-style accessors to a class. It allows you to define 
getter and setter methods for class attributes. The parameter is the name of 
the keyword to create accessors.

  package Toolkit;
  Moose::LOP->new( 'MyClass' )->have_accessors( 'acc' );
  ...
  package MyClass;
  use Toolkit;
  acc foo => ( is => 'ro', default => sub { 'foo' } );
  ...
  package main;
  use MyClass;
  my $obj = MyClass->new();
  print $obj->foo();    # prints "foo"

B<Note:> This method is based on C<< Class::MOP::Class->add_attribute >>.

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

  my $class = Moose::LOP->new( 'ParentClass' );
  $class->create_method( 'foo', sub { return 'foo'; } );
  my $subclass = Moose::LOP->new( 'ChildClass' );
  $subclass->import_methods( 'ParentClass', 'foo' );
  my $obj = ChildClass->new();
  print $obj->foo();    # prints "foo"

B<Note:> This method is based on C<< Class::MOP::Class->get_method >> and 
C<< Class::MOP::Class->add_method >>.

=head2 init

  my $self = $self->init($class);

This constructor initializes a class. However, it does not create a new class, 
but sets the current class to the specified one, if it exists. You can then 
attach other methods to this method or save it in a variable in order to use it 
repeatedly. For example:

  Moose::LOP->init( 'SomeClass' );

=head2 list_methods

  my @methods = $self->list_methods();

This method returns a list of all the methods within an initialized class. It 
helps in introspection by listing all available methods. For example:

  my $class = Moose::LOP->new( 'MyClass' );
  $class->create_method( 'foo', sub { return 'foo'; } );
  my @methods = $class->list_methods();
  print join( ", ", @methods );    # prints "foo"

B<Note:> This method is based on C<< Class::MOP::Class->get_all_method_names >>.

=head2 method_exists

  my $bool = $self->method_exists( | $class, $method);

This method checks if a specific method exists in a class. It returns a boolean 
value indicating whether the method is defined. For example:

  my $class = Moose::LOP->new( 'MyClass' );
  $class->create_method( 'foo', sub { return 'foo'; } );
  if ( $class->method_exists( 'foo' ) ) {
    print "Method foo exists\n";
  }
  else {
    print "Method foo does not exist\n";
  }

B<Note:> This method is based on C<< Class::MOP::Class->has_method >>.

=head2 override_method

  my $self | undef = $self->override_method($name, $method);

This method allows you to replace an existing method in a class with a new 
implementation. It is useful for modifying the behavior of inherited methods. 
For example:

  my $class = Moose::LOP->new( 'MyClass' );
  $class->create_method( 'foo', sub { return 'foo'; } );
  my $obj = MyClass->new();
  print $obj->foo();    # prints "foo"
  $class->override_method( 'foo', sub { return 'bar'; } );
  print $obj->foo();    # prints "bar"

B<Note:> This method is based on C<< Class::MOP::Class->method_exists >> and 
C<< Class::MOP::Class->add_method >>.

=head2 subclasses

  my @list = $self->subclasses();

This method returns a list of all subclasses that inherit from the specified 
class. It allows you to identify which classes are derived from a particular 
base class. For example:

  my $class = Moose::LOP->new( 'ParentClass' );
  my $subclass = Moose::LOP->new( 'ChildClass' );
  $subclass->extend_class( 'ParentClass' );
  my @subclasses = $class->subclasses();
  print join( ", ", @subclasses );    # prints "ChildClass"

B<Note:> This method is based on C<< Class::MOP::Class->subclasses >>.

=head2 superclasses

  my @list = $self->superclasses();

This method returns a list of all superclasses (base classes) from which the 
specified class inherits. It allows you to trace the inheritance hierarchy of a 
class. For example:

  my $parent_class = Moose::LOP->new( 'ParentClass' );
  my $child_class  = Moose::LOP->new( 'ChildClass' );
  $child_class->extend_class( 'ParentClass' );
  my @superclasses = $child_class->superclasses();
  print join( ", ", @superclasses );    # prints "ParentClass"

B<Note:> This method is based on C<< Class::MOP::Class->superclasses >>.

=head1 REQUIRES

L<Carp>

L<Class::LOP>

L<Moose>

=head1 SEE ALSO

L<Class::MOP>

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 CONTRIBUTORS

Brad Haywood <brad@perlpowered.com>

L<Moose/AUTHORS> and L<Moose/CONTRIBUTORS>

=head1 LICENSE

Copyright (c) 2024 the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
