package Class::Fields::LOP;
# ABSTRACT: A Lightweight Object Protocol for fields based classes.

use strict;
use warnings;

our $VERSION   = '0.05';
our $AUTHORITY = 'cpan:BRICKPOOL';

use Carp ();

BEGIN { sub XS () { eval q[ use Class::XSAccessor ]; !$@ } }

BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }
BEGIN { require Devel::GlobalDestruction unless $] >= 5.014 }

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
  no warnings 'once';
  return defined *{"${class}::FIELDS"}{HASH};
};

sub extend_class {    # $self|undef (@parents)
  my ( $self, @parents ) = @_;
  return unless @parents;

  # inheritor
  my $class = $self->name;

  # We want to recognize multiple inheritance and 
  # separate mothers (bases) and fathers (multiples).
  # Part of the following code is taken from base::import()
  my @fathers;
  NEXT: {
    # List of base classes from which we will inherit %FIELDS.
    my $fields_base;
    my @bases;
    for my $i ( 0 .. $#parents ) {
      my $base = $parents[$i];
      next if grep { $_->isa( $base ) } ( $class, @bases );
      push @bases, $base;
      if ( base::has_fields( $base ) || base::has_attr( $base ) ) {
        if ( $fields_base ) {
          # Detect multiply inherit fields
          push @fathers, delete $parents[$i];
          redo NEXT;
        }
        $fields_base = $base;
      } #/ if ( base::has_fields(...))
    } #/ for my $i ( 0 .. $#parents)
  } #/ NEXT:

  # the mothers first
  my $mothers = join ' ' => @parents;
  eval qq{
    package $class; 
    use base qw( $mothers );
    return 1;
  } or Carp::croak( $@ );

  # then the fathers if available
  if ( @fathers ) {
    no strict 'refs';
    push @{"${class}::ISA"}, @fathers;    # dies if a loop is detected
  }

  push @{ $self->{classes} }, $class;    # for compatibility
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
          Class::XSAccessor->import(
            class => $class,
            $mutator => { $attr => $attr },
          );
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
  return if $target->can( 'new' );

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
        my $ref = ref $_[0];
        if ( @_ == 1 && $ref ) {
          Carp::croak( 'Unable to coerce to HASH reference from unknown '.
            "reference type ($ref)" ) 
              if $ref ne 'HASH';
          $proto = $_[0];
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
          for grep { exists $this->{_attributes}{$_} }
            reverse @{ mro::get_linear_isa( $class ) };
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
        my $build = *{$_.'::BUILD'}{CODE};
        $build->( $self, $proto ) if $build;
      } reverse @{ mro::get_linear_isa( $class ) };
    }

    return $self;
  }; #/ sub new

  # The destructor for the base class is created as follows ..
  my $DESTROY = "${target}::DESTROY";
  *$DESTROY = sub {    # void ()
    my $self = shift;
    my $class = ref $self || $self;

    my $in_global_destruction = defined ${^GLOBAL_PHASE}
      ? ${^GLOBAL_PHASE} eq 'DESTRUCT'
      : Devel::GlobalDestruction::in_global_destruction();

    # Call all DEMOLISH methods starting with the derived classes.
    DEMOLISHALL: {
      map {
        my $demolish = *{$_.'::DEMOLISH'}{CODE};
        $demolish->( $self, $in_global_destruction ) if $demolish;
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
  my $fields     = base::get_fields( $class );
  my $attributes = base::get_attr( $class );
  for my $f ( keys %$fields ) {
    my $no    = $fields->{$f};
    my $fattr = $attributes->[$no];

    # we only want to have the newly defined %FIELDS of $class
    next if !defined $fattr;
    next if $fattr & base::INHERITED;
    $attr->{$f} = $no;
  }

  # merge the attribute values into the return hash
  map { 
    $attr->{$_} = $self->{_attributes}{$class}{$_}
      if exists $self->{_attributes}{$class}{$_};
  } keys %$attr;

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

version 0.05

=head1 DESCRIPTION

Based on the L<fields> pragma, an alternative use of L<Class::LOP> is 
implemented here in order to obtain the advantages such as the hash check 
using L<Hash::Util> and the use of C<%FIELDS>.

For this reason, this package was developed based on the L<base> distribution, 
which also contains the L<fields> package.

When available, L<Class::XSAccessor> is used to generate the class accessors.

This is a derived class from L<Class::LOP>, which means that we inherit the 
interface of the base classes. 

The following L<Class::LOP> methods have been overwritten:

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

L<Devel::GlobalDestruction> for perl < v5.14

L<fields>

L<MRO::Compat> for perl < v5.10

=head1 SEE ALSO

L<Class::Fields>

L<whyfields>

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 CONTRIBUTORS

Brad Haywood <brad@perlpowered.com>

Michael G Schwern <schwern@pobox.com>

=head1 LICENSE

Copyright (c) 2024-2025 the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
