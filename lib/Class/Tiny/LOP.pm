package Class::Tiny::LOP;
# ABSTRACT: A Lightweight Object Protocol for Class::Tiny.

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:BRICKPOOL';

require Carp;

use parent 'Class::LOP';

use Class::Tiny {
  _name       => sub { die 'required' },
  classes     => sub { [] },
  _attributes => sub { {} },
};

sub new {    # $self ($class)
  my ( $self, $class ) = @_;
  $self = $self->init( $class ) unless ref $self;
  $class->create_constructor()
    unless $self->class_exists( $class );
  return $self;
}

sub init {    # $self ($class)
  my ( $self, $class ) = @_;
  $self = $self->Class::Tiny::Object::new( _name => $class ) unless ref $self;
  return $self;
}

sub have_accessors {    # $self|undef ($name)
  my ( $self, $name ) = @_;
  my $class = $self->name;
  if ( $self->class_exists( $class ) ) {
    no strict 'refs';
    my $slot = "${class}::${name}";
    *$slot = sub {
      my ( $attr, %args ) = @_;
      my $value = do {
        my $d = delete $args{default};
        my $r = ref $d;
        $r eq 'HASH'  ? sub { +{%$d} } :
        $r eq 'ARRAY' ? sub { [@$d] }  :
        $r eq 'CODE'  ? $d             :
                        sub { $d }     ;
      };
      my $is = delete $args{is} || 'rw';
      $self->_add_attribute( $class, $attr, $value );
      if ( $is eq 'ro' and *{"${class}::${attr}"}{CODE} ) {
        $self->add_hook(
          type   => 'before',
          name   => $attr,
          method => sub {
            Carp::croak( "Usage: ${class}::$attr(self)" ) if $#_;
          },
        );
      }
      return;
    }; #/ sub
    return $self;
  }
  Carp::croak( "Can't create accessors in class '$class', ".
    "because it doesn't exist" );
} #/ sub have_accessors

sub create_constructor {    # $self ()
  my ( $self ) = @_;
  my $class = $self->name;
  unless ( $class->isa( 'Class::Tiny::Object' ) ) {
    Carp::carp( "constructor is already implemented" )
      if $class->can('new');
    Class::Tiny->prepare_class( $class );
  }
  return $self;
}

sub create_class {    # $bool ($class)
  my ( $self, $class ) = @_;
  if ( $self->class_exists( $self->name ) ) {
    Carp::carp( "Can't create class '$class'. Already exists" );
    return !!0;
  }
  else {
    $self->create_constructor();
    return !!1;
  }
} #/ sub create_class

sub get_attributes {    # \%attr ()
  my $self  = shift;
  my $class = $self->name;

  # %a: %attr from this $class (which includes parents)
  my %a = %{ Class::Tiny->get_all_attribute_defaults_for( $class ) };

  # %b: %attr from the superclasses (only the parents)
  my %b = ();
  %b = ( %b, %{ Class::Tiny->get_all_attribute_defaults_for( $_ ) } )
    for reverse $self->superclasses();

  # build %attr that are not contained the entries from the parents
  my %attr = map { $_ => $a{$_} } 
    grep { !exists $b{$_} } keys %a;

  return \%attr;
}

sub _add_attribute {    # void ($class, $attr, \&value)
  my ( $self, $class, $attr, $value ) = @_;
  Class::Tiny->create_attributes( $class, { $attr => $value } );
  $self->SUPER::_add_attribute( $class, $attr, $value );
  return;
}

1;

__END__

=pod

=head1 NAME

Class::Tiny::LOP - The Lightweight Object Protocol for Class::Tiny

=head1 VERSION

version 0.01

=head1 DESCRIPTION

L<Class::Tiny> is an efficient class construction kit that is ideal for projects
where L<Moose> and L<Moo> are too I<heavy>.

For this reason, this package was developed, which is based on L<Class::Tiny> 
and L<Class::LOP>.

=head1 METHODS

This is a derived class from L<Class::Tiny::Object|Class::Tiny> and 
L<Class::LOP>, which means that we inherit the interface of the base classes. 

The following L<Class::LOP> methods have been overwritten:

=head1 METHODS

=head2 new

  my $self = $self->new($class);

=head2 create_class

  my $self = $self->create_class($class);

=head2 create_constructor

  my $self = $self->create_constructor();

=head2 get_attributes

  my \%attr = $self->get_attributes();

=head2 have_accessors

  my $self | undef = $self->have_accessors($name);

=head2 init

  my $self = $self->init($class);

=head2 superclasses

  my @list = $self->superclasses();

=head1 REQUIRES

L<Carp>

L<Class::LOP>

L<Class::Tiny>

L<parent>

=head1 SEE ALSO

L<Class::Tiny::Antlers>

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
