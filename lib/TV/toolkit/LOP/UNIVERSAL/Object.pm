package UNIVERSAL::Object::LOP;
# ABSTRACT: A Lightweight Object Protocol for UNIVERSAL::Object.

use strict;
use warnings;

our $VERSION   = '0.05';
our $AUTHORITY = 'cpan:BRICKPOOL';

require Carp;

BEGIN { sub XS () { eval q[ use Class::XSAccessor ]; !$@ } }

BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }

use parent 'Class::LOP';
use parent 'UNIVERSAL::Object::Immutable';

our %HAS; BEGIN {
    %HAS = (
      _name       => sub { die 'required' },
      classes     => sub { [] },
      _attributes => sub { {} },
    );
}

sub new {    # $self ($class)
  my ( $self, $class ) = @_;
  $self = $self->init( $class ) unless ref $self;
  $self->create_constructor()
    unless $self->class_exists( $class );
  return $self;
}

sub init {    # $self ($class)
  my ( $self, $class ) = @_;
  return ref $self
    ? $self
    : $self->UNIVERSAL::Object::Immutable::new( _name => $class );
}

sub class_exists {    # $bool (| $class)
  my ( $self, $class ) = @_;
  $class ||= $self->name;
  return $class->isa( 'UNIVERSAL::Object' );
};

sub extend_class {    # $self|undef (@mothers)
  my $self = shift;
  return unless @_;

  # get reference to %HAS (create new %HAS if necessary)
  my $class = $self->name;
  no strict 'refs';
  %{"${class}::HAS"} = () unless %{"${class}::HAS"};
  my $has = \%{"${class}::HAS"};

  # %a: %HAS from this $class (without parents)
  my %b = ();
  %b = ( %b, %{$_.'::HAS'} ) 
    for reverse $self->superclasses();
  my %a = map { $_ => $has->{$_} } 
    grep { !exists $b{$_} } keys %$has;

  $self->SUPER::extend_class( @_ );

  # %b: %HAS from all superclasses (including new parents)
  %b = ();
  %b = ( %b, %{$_.'::HAS'} ) 
    for reverse $self->superclasses();

  # We have new parent classes, so %HAS must be regenerated
  %$has = ( %b, %a );

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
      if ( $access =~ /^ro|rw$/ ) {
        if ( XS ) {
          my $mutator = $access eq 'ro' ? 'getters' : 'accessors';
          eval qq[
            use Class::XSAccessor
              class => '$class',
              $mutator => { '$attr' => '$attr' };
            return 1;
          ] or Carp::croak( "Can't create accessor in class '$class': $@" );
        }
        else {
          my $acc = "${class}::${attr}";
          unless ( exists &$acc ) {
            *{$acc} = $access eq 'ro'
                    ? sub { 
                        $#_ ? Carp::croak("Usage: ${class}::$attr(self)")
                            : $_[0]->{$attr}
                      }
                    : sub { 
                        $#_ ? $_[0]->{$attr} = $_[1]
                            : $_[0]->{$attr} 
                      }
          }
        }
      }
      elsif ( $access ne 'bare' ) {
        Carp::carp "Can't create accessor in class '$class': ".
          "unknown argument '$access'."
      }

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
  return if $self->class_exists();
  Carp::carp( "constructor is already implemented" )
    if $class->can('new');
  $self->extend_class( qw( UNIVERSAL::Object ) );
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

# Returns the %slots without those inherited from the parents.
sub get_attributes {    # \%slots ()
  my $self  = shift;
  my $class = $self->name;

  # An unfortunate hack that needs to be fixed ..
  my $SLOTS = sub {
    my $class = shift;
    $class->can( 'SLOTS' )
      ? $class->SLOTS()
      : do { no strict 'refs'; %{"${class}::HAS"} || () };
  };

  # %a: %slots from this $class (which includes parents)
  my %a = $class->$SLOTS();

  # %b: %slots from the superclasses (only the parents)
  my %b = ();
  %b = ( %b, $_->$SLOTS() )
    for reverse $self->superclasses();

  # build %slots that are not contained the entries from the parents
  my %slots = map { $_ => $a{$_} } 
    grep { !exists $b{$_} } keys %a;

  return \%slots;
}

sub _add_attribute {    # void ($class, $attr, \&value)
  my ( $self, $class, $attr, $value ) = @_;
  no strict 'refs';
  my $has = *{"${class}::HAS"}{HASH};

  # if %HAS does not exist, it is a base class for which %HAS must be created.
  unless ( $has ) {
    # Create empty %HAS and get the reference
    %{"${class}::HAS"} = ();
    $has = \%{"${class}::HAS"};

    # copy all superclass entries to %HAS
    %$has = ( %$has, %{$_.'::HAS'} ) 
      for reverse $self->superclasses();
  }

  $has->{$attr} = $value;
  $self->SUPER::_add_attribute( $class, $attr, $value );
  return;
}

1;

__END__

=pod

=head1 NAME

UNIVERSAL::Object::LOP - The Lightweight Object Protocol for UNIVERSAL::Object

=head1 VERSION

version 0.05

=head1 DESCRIPTION

L<UNIVERSAL::Object> is a wonderful base class. The author I<Stevan Little> has 
added the pragma L<slots> for practical use, which is based on the L<MOP> 
distribution. In my opinion, this combination made the usage not as 
I<light-footed> as originally started. 

For this reason, this package was developed, which is not based on the L<MOP> 
distribution, but on the L<Class::LOP> package.

When available, L<Class::XSAccessor> is used to generate the class accessors.

=head1 METHODS

This is a derived class from L<UNIVERSAL::Object> and L<Class::LOP>, which means
that we inherit the interface of the base classes. 

The following L<Class::LOP> methods have been overwritten:

=head1 METHODS

If you need information or further help, you should take a look at the 
L<Moose::LOP> or L<Class::LOP> documentation.

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

=head2 get_attributes

  my \%slots = $self->get_attributes();

=head2 have_accessors

  my $self | undef = $self->have_accessors($name);

=head2 init

  my $self = $self->init($class);

=head1 REQUIRES

L<Carp>

L<Class::LOP>

L<parent>

L<UNIVERSAL::Object>

=head1 SEE ALSO

L<MOP>

L<slots>

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 CONTRIBUTORS

Brad Haywood <brad@perlpowered.com>

Stevan Little <stevan@cpan.org>

=head1 LICENSE

Copyright (c) 2024 the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
