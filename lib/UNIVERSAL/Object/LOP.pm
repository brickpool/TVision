package UNIVERSAL::Object::LOP;
# ABSTRACT: A Lightweight Object Protocol for UNIVERSAL::Object.

use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:BRICKPOOL';

require Carp;

BEGIN { sub XS () { eval q[ use Class::XSAccessor ]; !$@ } }

BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }

use parent 'Class::LOP';
use parent 'UNIVERSAL::Object';

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
  $class->create_constructor()
    unless $self->class_exists( $class );
  return $self;
}

sub init {    # $self ($class)
  my ( $self, $class ) = @_;
  $self = $self->UNIVERSAL::Object::new( _name => $class ) unless ref $self;
  return $self;
}

sub superclasses {    # \@array ()
  my $self = shift;
  my $class = $self->name;
  my $isa = mro::get_linear_isa( $class );
  return @$isa[ 1 .. $#$isa ];
}

sub extend_class {    # $self|undef (@mothers)
  my $self = shift;
  return unless @_;
  $self->SUPER::extend_class( @_ );

  # We may have new parent classes, so %HAS must be regenerated.
  no strict 'refs';
  my $class = $self->name;
  %{"${class}::HAS"} = () unless %{"${class}::HAS"};
  my $HAS = \%{"${class}::HAS"};
  for my $isa ( reverse $self->superclasses() ) {
    if ( my $isa_HAS = \%{"${isa}::HAS"} ) {
      map { $HAS->{$_} = $isa_HAS->{$_} } keys %$isa_HAS;
    }
  }

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
      $self->_add_attribute( $class, $attr, $value );
      my $is = delete $args{is} || 'rw';
      if ( XS ) {
        my $mutator = $is eq 'ro' ? 'getters' : 'accessors';
        eval qq[
          use Class::XSAccessor
            replace => 1,
            class => '$class',
            $mutator => { '$attr' => '$attr' };
          return 1;
        ] or Carp::confess( "Can't create accessor in class '$class': $@" );
      }
      else {
        no warnings 'redefine';
        my $acc = "${class}::${attr}";
        *{$acc} = $is eq 'ro'
                ? sub { 
                    $#_ ? Carp::confess("Usage: ${class}::$attr(self)")
                        : $_[0]->{$attr}
                  }
                : sub { 
                    $#_ ? $_[0]->{$attr} = $_[1]
                        : $_[0]->{$attr} 
                  }
      }
    }; #/ sub
    return $self;
  }
  Carp::confess( "Can't create accessors in class '$class', ".
    "because it doesn't exist" );
} #/ sub have_accessors

sub create_constructor {    # $self ()
  my ( $self ) = @_;
  my $class = $self->name;
  unless ( $class->isa( 'UNIVERSAL::Object' ) ) {
    Carp::carp( "constructor is already implemented" )
      if $class->can('new');
    $self->extend_class( qw( UNIVERSAL::Object ) );
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

# Returns the local %HAS entries without those inherited from the parents.
sub get_attributes {    # \%has ()
  my $self  = shift;
  my $class = $self->name;

  # get %HAS from this $class (which includes the superclasses)
  my %a = $class->SLOTS();

  # get only %HAS from the superclasses
  my %b = ();
  %b = ( %b, $_->SLOTS() ) 
    for $self->superclasses();

  # determine %HAS from this $class that are not contained in the superclasses
  my %has = map { $_ => $a{$_} } 
    grep { !exists $b{$_} } keys %a;

  return \%has;
}

sub _add_attribute {    # void ($class, $attr, \&value)
  my ( $self, $class, $attr, $value ) = @_;
  no strict 'refs';
  my $HAS = \%{"${class}::HAS"};

  # if %HAS does not exist, it is a base class for which %HAS must be created.
  unless ( %$HAS ) {
    %{"${class}::HAS"} = ();
    $HAS = \%{"${class}::HAS"};
    for my $isa ( reverse $self->superclasses() ) {
      if ( my $isa_HAS = \%{"${isa}::HAS"} ) {
        map { $HAS->{$_} = $isa_HAS->{$_} } keys %$isa_HAS;
      }
    }
  }

  $HAS->{$attr} = $value;
  $self->SUPER::_add_attribute( $class, $attr, $value );
  return;
}

1;

__END__

=pod

=head1 NAME

UNIVERSAL::Object::LOP - The Lightweight Object Protocol for UNIVERSAL::Object

=head1 VERSION

version 0.03

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

=head2 new

  my $self = $self->new($class);

=head2 create_class

  my $self = $self->create_class($class);

=head2 create_constructor

  my $self = $self->create_constructor();

=head2 extend_class

  my $self | undef = $self->extend_class(@mothers);

=head2 get_attributes

  my \%has = $self->get_attributes();

=head2 have_accessors

  my $self | undef = $self->have_accessors($name);

=head2 init

  my $self = $self->init($class);

=head2 superclasses

  my \@array = $self->superclasses();

=head1 REQUIRES

L<Carp>

L<Class::LOP>

L<UNIVERSAL::Object>

=head1 SEE ALSO

L<MOP>

L<slots>

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
