package fields::LOP;
# ABSTRACT: A Lightweight Object Protocol for fields based classes.

use strict;
use warnings;

our $VERSION   = '0.01';
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
  $class->create_constructor()
    unless $self->class_exists( $class );
  return $self;
}

sub init {    # $self ($class)
  my ( $self, $class ) = @_;
  $self = fields::new( $self ) unless ref $self;
  Carp::confess( "No class specified" ) 
    unless $class;
  $self->{_name} = $class;
  $self->{classes} = [];
  $self->{_attributes} = \%_attributes;
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
  my $mothers = join ' ' => @_;
  return unless $mothers;
  my $class = $self->name;
  eval qq{
    package $class; 
    use base qw( $mothers );
    return 1;
  } or Carp::confess( $@ );
  push @{ $self->{classes} }, $class;
  return $self;
} #/ sub extend_class

sub have_accessors {
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
      my $is = delete $args{is} || 'rw';

      # Add attribute and create the accessor incl. default handling
      $self->_add_attribute( $class, $attr, $value );
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
        *$acc = $is eq 'ro'
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
  no strict 'refs';
  my $this = shift;
  my $target = $this->name;

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
          Carp::confess( 'Unable to coerce to HASH reference from unknown '.
            "reference type ($ref)" ) 
              if ( ref $arg || '' ) ne 'HASH';
          $proto = $arg;
        } #/ if ( @_ == 1 && ref $_...)
        else {
          Carp::confess( 'Unable to coerce to HASH reference from LIST with '.
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
        foreach my $super ( reverse @{ mro::get_linear_isa( $class ) } ) {
          map { $slots{$_} = $this->{_attributes}{$super}{$_} }
            keys %{ $this->{_attributes}{$super} };
        }
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
        my $super = $_;
        my $build = "${super}::BUILD";
        $build->( $self, $proto ) if exists( &$build )
      } reverse @{ mro::get_linear_isa( $class ) };
    }

    return $self;
  }; #/ sub new

  return if $target->can( 'DESTROY' );

  # The destructor for the base class is created as follows ..
  my $DESTROY = "${target}::DESTROY";
  *$DESTROY = sub {    # void ()
    my $self = shift;
    my $class = ref $self || $self;

    # Call all DEMOLISH methods starting with the derived classes.
    DEMOLISHALL: {
      map {
        my $super    = $_;
        my $demolish = "${super}::DEMOLISH";
        $demolish->( $self ) if exists( &$demolish );
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
    } or Carp::confess( $@ );
  }
  $self->SUPER::_add_attribute( $class, $attr, $value );
  return;
} #/ sub _add_attribute

1;

__END__

=pod

=head1 NAME

fields::LOP - The Lightweight Object Protocol for fields based classes

=head1 VERSION

version 0.01

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

=head2 new

  my $self = $self->new($class);

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

=head2 superclasses

  my \@array = $self->superclasses();

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

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
