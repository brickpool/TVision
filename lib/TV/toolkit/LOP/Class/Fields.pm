package Class::Fields::LOP;
# ABSTRACT: A Lightweight Object Protocol for fields based classes.

use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:BRICKPOOL';

require Carp;

BEGIN { sub XS () { eval q[ use Class::XSAccessor ]; !$@ } }

BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }

use base 'Class::LOP';
use fields qw(
  _name
  classes
  _attributes
);

our %_attributes;

sub new {    # $self ($class)
  my ( $self, $class ) = @_;
  $self = $self->init( $class ) unless ref $self;
  $self->create_constructor()
    unless $self->class_exists( $class );
  return $self;
}

sub init {    # $self ($class)
  my ( $self, $class ) = @_;
  $self = fields::new( $self ) unless ref $self;
  Carp::croak( "No class specified" ) 
    unless $class;
  $self->{_name} = $class;
  $self->{classes} = [];
  $self->{_attributes} = \%_attributes;
  return $self;
}

sub class_exists {    # $bool (| $class)
  my ( $self, $class ) = @_;
  $class ||= $self->name;
  no strict 'refs';
  return *{"${class}::FIELDS"}{HASH};
};

sub extend_class {    # $self|undef (@mothers)
  my $self = shift;
  my $mothers = join ' ' => @_;
  return unless $mothers;
  my $class = $self->name;
  eval qq{
    package $class; 
    use base qw( $mothers );
    return 1;
  } or Carp::croak( $@ );
  push @{ $self->{classes} }, $class;
  return $self;
} #/ sub extend_class

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
            *$acc = $access eq 'ro'
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
  no strict 'refs';
  my $this = shift;
  my $target = $this->name;

  %{"${target}::FIELDS"} = () unless %{"${target}::FIELDS"};
  return if $target->can('new');

  # Create a constructor for the specified target
  my $new = "${target}::new";
  *$new = sub {    # $obj (@)
    my $self  = shift;
    my $class = ref $self || $self;

    my $proto;
    BUILDARGS: {
      if ( $class->can( 'BUILDARGS' ) ) {
        # If BUILDARGS exists, we use this ..
        $proto = $class->BUILDARGS( @_ );
      } 
      else {
        # .. otherwise we take arg values as hashref or hash.
        if ( @_ == 1 && ref $_[0] ) {
          my $arg = shift;
          my $ref = ref $arg;
          Carp::croak( 'Unable to coerce to HASH reference from unknown '.
            "reference type ($ref)" ) 
              if ( ref $arg || '' ) ne 'HASH';
          $proto = $arg;
        } #/ if ( @_ == 1 && ref $_...)
        else {
          Carp::croak( 'Unable to coerce to HASH reference from LIST with '.
            'odd number of elements' ) 
              if @_ % 2 == 1;
          $proto = +{ @_ };
        }
      }
    }

    CREATE: {
      # bless $self, if not already done.
      REPL: {
        $self = fields::new( $class ) unless ref $self;
      }
      
      my %slots = ();
      SLOTS: {
        %slots = ( %slots, %{ $this->{_attributes}{$_} } )
          for reverse @{ mro::get_linear_isa( $class ) };
      }

      # Valid arguments or default values are passed to $self
      $self->{$_} = exists $proto->{$_}
                  ? $proto->{$_}
                  : $slots{$_}->( $self, $proto )
                for keys %slots;
    }

    # Call all BUILD methods starting with the base class up to the derived 
    # classes.
    BUILDALL: {
      map {
        my $build = $_.'::BUILD';
        $build->( $self, $proto ) if exists &$build;
      } reverse @{ mro::get_linear_isa( $class ) };
    }

    return $self;
  }; #/ sub new

  # The destructor for the base class is created as follows ..
  my $DESTROY = "${target}::DESTROY";
  *$DESTROY = sub {    # void ()
    my $self = shift;
    my $class = ref $self || $self;

    # Call all DEMOLISH methods starting with the derived classes.
    DEMOLISHALL: {
      map {
        my $demolish = $_.'::DEMOLISH';
        $demolish->( $self ) if exists &$demolish;
      } @{ mro::get_linear_isa( $class ) };
    }
    return;
  }; #/ *$DESTROY = sub

  return $this;
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

# Returns the locally defined fields without the fields inherited from the 
# parents.
sub get_attributes {    # \%fields ()
  my $self  = shift;
  my $class = $self->name;
  my $attr;

  # Part of the following code is taken from fields::_dump()
  my $fields = base::get_fields( $class );
  for my $f ( keys %$fields ) {
    my $no    = $fields->{$f};
    my $fattr = base::get_attr( $class )->[$no];

    # we only want to have the newly defined %FIELDS of $class
    next if !defined $fattr;
    next if $fattr & base::INHERITED;
    $attr->{$f} = $no;
  }

  return $attr;
} #/ sub get_attributes

sub _add_attribute {    # void ($class, $attr, \&value)
  my ( $self, $class, $attr, $value ) = @_;
  if ( length( $attr ) ) {
    eval qq{
      package $class; 
      use fields '$attr';
      return 1;
    } or Carp::croak( $@ );
  }
  $self->SUPER::_add_attribute( $class, $attr, $value );
  return;
} #/ sub _add_attribute

1;

__END__

=pod

=head1 NAME

Class::Fields::LOP - The Lightweight Object Protocol for fields based classes

=head1 VERSION

version 0.03

=head1 DESCRIPTION

Based on the L<fields> pragma, an alternative use of L<Class::LOP> is 
implemented here in order to obtain the advantages such as the hash check 
using L<Hash::Util> and the use of C<%FIELDS>.

For this reason, this package was developed based on the L<base> distribution, 
which also contains the L<fields> package.

When available, L<Class::XSAccessor> is used to generate the class accessors.

=head1 METHODS

This is a derived class from L<Class::LOP>, which means that we inherit the 
interface of the base classes. 

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

  my \%fields = $self->get_attributes();

=head2 have_accessors

  my $self | undef = $self->have_accessors($name);

=head2 init

  my $self = $self->init($class);

=head1 REQUIRES

L<base>

L<Carp>

L<Class::LOP>

L<fields>

=head1 SEE ALSO

L<Class::Fields>

L<whyfields>

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 CONTRIBUTORS

Brad Haywood <brad@perlpowered.com>

Michael G Schwern <schwern@pobox.com>

=head1 LICENSE

Copyright (c) 2024 the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
