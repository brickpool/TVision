package UNIVERSAL::Object::LOP;
# ABSTRACT: A Lightweight Object Protocol for UNIVERSAL::Object.

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:BRICKPOOL';

BEGIN { sub XS () { eval q[ use Class::XSAccessor ]; !$@ } }

BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }

use parent 'Class::LOP';
use parent 'UNIVERSAL::Object';

our %HAS; BEGIN {
    %HAS = ( 
      _name => sub { die 'required' },
      classes => sub { [] },
    );
}

sub new { # $self (%args)
  goto &UNIVERSAL::Object::new;
}

sub init { # $self ($class)
  return __PACKAGE__->new( _name => $_[1] );
}

sub superclasses { # \@array ()
  my $self = shift;
  my $class = $self->{_name};
  return @{ mro::get_linear_isa( $class ) };
}

sub extend_class {  # $self|undef (@mothers)
  my $self = shift;
  return unless @_;
  $self->SUPER::extend_class( @_ );

  # We may have new parent classes, so %HAS must be regenerated.
  no strict 'refs';
  my $class = $self->{_name};
  %{"${class}::HAS"} = () unless %{"${class}::HAS"};
  my $HAS = \%{"${class}::HAS"};
  for my $isa ( reverse $self->superclasses() ) {
    if ( my $isa_HAS = \%{"${isa}::HAS"} ) {
      map { $HAS->{$_} = $isa_HAS->{$_} } keys %$isa_HAS;
    }
  }

  return $self;
}

sub have_accessors { # $self|undef ($name)
  my ( $self, $name ) = @_;
  my $class = $self->{_name};
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
              ] or warn "Can't create accessor in class '$class': $@";
      }
      else {
        require Carp;
        no warnings 'redefine';
        my $acc = "${class}::${attr}";
        *{$acc} = $is eq 'ro'
                ? sub { $#_
                        ? Carp::croak "Usage: ${class}::$attr(self)"
                        : $_[0]->{$attr}
                  }
                : sub { $#_
                        ? $_[0]->{$attr} = $_[1]
                        : $_[0]->{$attr} 
                  }
      }
    }; #/ sub
    return $self;
  }
  else {
    warn "Can't create accessors in class '$class', because it doesn't exist";
    return;
  }
} #/ sub have_accessors

sub create_constructor { # $self ()
  my ( $self ) = @_;
  my $caller = $self->{_name};
  if ( !$caller->isa( 'UNIVERSAL::Object' ) ) {
    warn "constructor is already implemented" 
      if $caller->can('new');
    $self->extend_class( qw( UNIVERSAL::Object ) );
  }
  return $self;
}

sub create_class { # $self ($class)
  my ( $self, $class ) = @_;
  my $caller = $self->{_name};
  if ( $self->class_exists( $caller ) ) {
    warn "Can't create class '$class'. Already exists";
    return !!0;
  }
  elsif ( !$caller->isa( 'UNIVERSAL::Object' ) ) {
    $self->extend_class( qw( UNIVERSAL::Object ) );
  }
  return !!1;
} #/ sub create_class

sub get_attributes { # \%has ()
  my $self  = shift;
  my $class = $self->{_name};
  return { $class->SLOTS() };
}

sub _add_attribute { # void ($class, $attr, \&default)
  my ( $self, $class, $attr, $value ) = @_;
  no strict 'refs';
  my $HAS = \%{"${class}::HAS"};

  # if %HAS does not exist, it is a base class for which %HAS must be created.
  unless ( $HAS ) {
    %{"${class}::HAS"} = ();
    $HAS = \%{"${class}::HAS"};
    for my $isa ( reverse $self->superclasses() ) {
      if ( my $isa_HAS = \%{"${isa}::HAS"} ) {
        map { $HAS->{$_} = $isa_HAS->{$_} } keys %$isa_HAS;
      }
    }
  }

  $HAS->{$attr} = $value;
  return;
}

1;

__END__

=pod

=head1 NAME

UNIVERSAL::Object::LOP - The Lightweight Object Protocol for UNIVERSAL::Object

=head1 VERSION

version 0.01

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

  my $self = $self->new(%args);

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
