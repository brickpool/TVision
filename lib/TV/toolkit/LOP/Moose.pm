package Moose::LOP;
# ABSTRACT: A Lightweight Object Protocol for Moose.

use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:BRICKPOOL';

use Carp ();
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
    push @{ $self->{classes} }, $self->name;    # for compatibility
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
  if ( my $meta = find_meta( $class ) ) {
    unless ( $meta->has_method( $name ) ) {
      Carp::carp "Cant't find '$name' in class $class - override_method()";
      return;
    }
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

version 0.03

=head1 DESCRIPTION

L<Moose> is an extension of the Perl 5 object system, which is based on the 
L<Class::MOP> distribution. 

This package was developed to support the interface provided by L<Class::LOP>. 
For this purpose, we use the L<Class::MOP> distribution internally.

This is a derived class of L<Moose::Object|Moose> using L<Class::LOP> as role, 
which means that we inherit the interface of the L<Moose::Object|Moose> base 
class, use the methods of L<Class::LOP> via L<Moose::Role> and extend them 
accordingly.

The following methods of the methods imported as a role of L<Class::LOP> have 
been overwritten:

=head1 METHODS

If you need information or further help, you should take a look at the 
L<TV::toolkit::LOP> or L<Class::LOP> documentation.

=head2 new

  my $self = $self->new($class);

=head2 class_exists

  my $bool = $self->class_exists( | $class);

B<Note:> This method is based on C<Moose::Util::find_meta>.

=head2 clone_object

  my $clone | undef = $self->clone_object();

B<Note:> This method is based on C<< Class::MOP::Class->clone_object >>.

=head2 create_class

  my $self = $self->create_class($class);

B<Note:> This constructor is based on C<< Moose::Meta::Class->create >>.

=head2 create_constructor

  my $self = $self->create_constructor();

B<Note:> This constructor is based on C<< Moose::Meta::Class->create >>.

=head2 create_method

  my $self | undef = $self->create_method($name, $code);

B<Note:> This method is based on C<< Class::MOP::Class->add_method >>.

=head2 delete_method

  my \&code | undef = delete_method($name);

B<Note:> This method is based on C<< Class::MOP::Class->remove_method >> and 
C<< Class::MOP::Method->body >>.

=head2 extend_class

  my $self | undef = $self->extend_class(@mothers);

B<Note:> This method is based on C<< Class::MOP::Class->superclasses >>.

=head2 get_attributes

  my \%attr = $self->get_attributes();

B<Note:> This method is based on C<< Class::MOP::Class->get_attribute >> and 
C<< Class::MOP::Attribute->default >>.

=head2 have_accessors

  my $self | undef = $self->have_accessors($name);

B<Note:> This method is based on C<< Class::MOP::Class->add_attribute >>.

=head2 import_methods

  my $self | undef = $self->import_methods($class, @methods);

B<Note:> This method is based on C<< Class::MOP::Class->get_method >> and 
C<< Class::MOP::Class->add_method >>.

=head2 init

  my $self = $self->init($class);

=head2 list_methods

  my @methods = $self->list_methods();

B<Note:> This method is based on C<< Class::MOP::Class->get_all_method_names >>.

=head2 method_exists

  my $bool = $self->method_exists( | $class, $method);

B<Note:> This method is based on C<< Class::MOP::Class->has_method >>.

=head2 override_method

  my $self | undef = $self->override_method($name, $method);

B<Note:> This method is based on C<< Class::MOP::Class->has_method >> and 
C<< Class::MOP::Class->add_method >>.

=head2 subclasses

  my @list = $self->subclasses();

B<Note:> This method is based on C<< Class::MOP::Class->subclasses >>.

=head2 superclasses

  my @list = $self->superclasses();

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

Copyright (c) 2024-2025 the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
