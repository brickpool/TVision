package Moo::LOP;
# ABSTRACT: A Lightweight Object Protocol for Moo.

use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:BRICKPOOL';

use Carp ();
use Moo;

with 'Moo::Class::LOP::Role';

has _name       => ( is => 'bare', required => 1 );
has classes     => ( is => 'bare', default => sub { [] } );
has _attributes => ( is => 'bare', default => sub { {} } );

sub BUILD {    # $self (@)
  my ( $self ) = @_;
  $self->create_constructor()
    unless $self->class_exists( $self->name );
  return;
};

around BUILDARGS => sub {    # $self ($class)
  my $orig = shift;
  my $self = shift;
  return @_ == 1 && !ref $_[0]
    ? $self->$orig( _name => $_[0] )
    : $self->$orig( @_ );
};

sub init {    # $self ($class)
  my ( $self, $class ) = @_;
  return ref $self
    ? $self
    : bless( $self->BUILDARGS( $class ), $self );
}

sub class_exists {    # $bool (| $class)
  my ( $self, $class ) = @_;
  $class ||= $self->name;
  return Moo->can( 'is_class' )
    ? Moo->is_class( $class )
    # following code is taken from 'Moo::is_class' >= v2.4
    : $Moo::MAKERS{$class} && $Moo::MAKERS{$class}{is_class};
}

sub extend_class {    # $self|undef (@mothers)
  my $self = shift;
  return unless @_;
  my $class = $self->name;
  Moo->_set_superclasses( $class, @_ );
  push @{ $self->{classes} }, $class;    # for compatibility
  return $self;
}

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
      my $spec_ref = { is => $access, default => $value };
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
  Carp::carp(
    "Can't create accessors in class '$class', because it doesn't exist" );
  return;
} #/ sub have_accessors

sub create_constructor {    # $self ()
  my ( $self ) = @_;
  my $class = $self->name;
  return if $self->class_exists( $class );
  Carp::carp( "constructor is already implemented" )
    if $class->can('new');

  unless ( $self->class_exists( $class ) ) {
    if ( Moo->can( 'make_class' ) ) {
      Moo->make_class( $class );
    }
    else {
      # following code is taken from 'Moo::import' < v2.4
      require Moo::_Utils;
      my $stash       = Moo::_Utils::_getstash( $class );
      my @not_methods = map { *$_{CODE} || () } grep !ref( $_ ), values %$stash;
      @{ $Moo::MAKERS{$class}{not_methods} = {} }{@not_methods} = @not_methods;
      $Moo::MAKERS{$class}{is_class} = 1;
      {
        no strict 'refs';
        @{"${class}::ISA"} = do {
          require Moo::Object;
          ( 'Moo::Object' );
        } unless @{"${class}::ISA"};
      }
    } #/ else [ if ( Moo->can( 'make_class'...))]
  } #/ unless ( $self->class_exists...)

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

BEGIN {
  package Moo::Class::LOP::Role;
  use Moo::Role;
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
  my $meta = Class::LOP->init( 'Class::LOP' );
  $meta->import_methods( __PACKAGE__, 
    grep { not $remove{$_} } $meta->list_methods()
  );

  $INC{"Moo/Class/LOP/Role.pm"} = 1;
}

__END__

=pod

=head1 NAME

Moo::LOP - The Lightweight Object Protocol for Moo

=head1 VERSION

version 0.03

=head1 DESCRIPTION

L<Moo> is a lightweight object orientation system, which is ideal for projects 
where L<Moose> is too I<heavy>. 

However, there is no meta-object support (by default). For this reason, this 
package was developed, which is based on L<Moo> and L<Class::LOP>.

This is a derived class of L<Moo::Object|Moo> using L<Class::LOP> as role, which
means that we inherit the interface of the I<Moo> base class, use the methods of
L<Class::LOP> via L<Moo::Role> and extend them accordingly.

The following methods of the methods imported as a role of L<Class::LOP> have 
been overwritten:

=head1 METHODS

If you need information or further help, you should take a look at the 
L<TV::toolkit::LOP> or L<Class::LOP> documentation.

=head2 new

  my $self = $self->new($class);

=head2 class_exists

  my $bool = $self->class_exists( | $class);

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

L<Moo>

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 CONTRIBUTORS

Brad Haywood <brad@perlpowered.com>

L<Moo/AUTHOR> and L<Moo/CONTRIBUTORS>

=head1 LICENSE

Copyright (c) 2024 the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
