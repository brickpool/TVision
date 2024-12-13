package Moo::LOP;
# ABSTRACT: A Lightweight Object Protocol for Moo.

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:BRICKPOOL';

require Carp;

use parent 'Class::LOP';
use parent 'Moo::Object';

BEGIN {
  local $Moo::sification::disabled = 1;
  require Moo;
  Moo->VERSION( 2.004 );
  Moo->import;
}

# bootstrap our own constructor
sub new {
  my ( $self, $class ) = @_;
  $self = $self->init( $class );
  $self->create_constructor( $class )
    unless $self->class_exists( $class );
  return $self;
}

sub init {    # $self ($class)
  my ( $self, $class ) = @_;
  return ref $self
    ? $self
    : bless( { _name => $class }, $self );
}

sub class_exists {    # $self ($class)
  my ( $self, $class ) = @_;
  $class ||= $self->name;
  return Moo->is_class( $class );
}

sub extend_class {    # $self|undef (@mothers)
  my $self = shift;
  return unless @_;
  my $class = $self->name;
  Moo->_set_superclasses( $class, @_ );
  push @{ $self->{classes} }, $class;
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
      my $access = delete $args{is} || 'rw';
      my $spec_ref = { is => $access, default => $value };
      $self->_add_attribute( $class, $attr, $value );
      Moo
        ->_constructor_maker_for( $class )
        ->register_attribute_specs( $attr, $spec_ref );
      Moo
        ->_accessor_maker_for( $class )
        ->generate_method( $class, $attr, $spec_ref );
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
  return if $self->class_exists( $class );
  Carp::carp( "constructor is already implemented" )
    if $class->can('new');
  Moo->make_class( $class );
  Moo->_constructor_maker_for( $class );
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

1;

__END__

=pod

=head1 NAME

Moo::LOP - The Lightweight Object Protocol for Moo

=head1 VERSION

version 0.01

=head1 DESCRIPTION

L<Moo> is a lightweight object orientation system, which is ideal for projects 
where L<Moose> is too I<heavy>. 

However, there is no meta-object support (by default). For this reason, this 
package was developed, which is based on L<Moo> and L<Class::LOP>.

=head1 METHODS

This is a derived class from L<Moo::Object|Moo> and L<Class::LOP>, which means 
that we inherit the interface of the base classes.

The following L<Class::LOP> methods have been overwritten:

=head1 METHODS

=head2 new

  my $self = $self->new($class);

=head2 create_class

  my $self = $self->create_class($class);

=head2 create_constructor

  my $self = $self->create_constructor();

=head2 extend_class

  my $self | undef = $self->extend_class(@mothers);

B<Note>: Calling extend_class more than once will REPLACE your superclasses.

=head2 have_accessors

  my $self | undef = $self->have_accessors($name);

=head2 init

  my $self = $self->init($class);

=head1 REQUIRES

L<Carp>

L<Class::LOP>

L<Moo> v2.4.0

L<parent>

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
