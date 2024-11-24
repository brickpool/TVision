package TV::toolkit;

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Module::Loaded ();
use mro ();

require Errno;
require fields;

BEGIN {
  our $name = 'PP';
  foreach my $toolkit ( 'fields', 'Class::Tiny', 'Moo', 'Moose' ) {
    if ( Module::Loaded::is_loaded $toolkit ) {
      $name = $toolkit;
      last;
    }
  }

  sub is_fields    (){ $name eq 'fields'      }
  sub is_ClassTiny (){ $name eq 'Class::Tiny' }
  sub is_Moo       (){ $name eq 'Moo'         }
  sub is_Moose     (){ $name eq 'Moose'       }
}

my $EINVAL = do {
  local $! = 1;
  $! = &Errno::EINVAL if exists &Errno::EINVAL;
  "$!";
};

# Returns all fields (including the inherited from parents) for the specified 
# target
sub all_slots {    # @metafields ($target)
  my $proto = shift;
  assert ( $proto );
  my $target = ref $proto || $proto;
  my @fields;
  if ( exists $fields::attr{$target} ) {
    # The following code is taken from fields::_dump()
    no strict 'refs';
    my %FIELDS = ();
    for my $pkg ( reverse @{ mro::get_linear_isa( $target ) } ) {
      %FIELDS = ( %FIELDS, %{"${pkg}::FIELDS"} );
    }
    for my $name ( sort { $FIELDS{$a} <=> $FIELDS{$b} } keys %FIELDS ) {
      my $no    = $FIELDS{$name} || next;
      my $fattr = $fields::attr{$target}[$no];
      push(
        @fields,
        {
          name        => $name,
          initializer => {
            is       => $target->can( $name ) ? 'bare' : 'rw',
            init_arg => $name,
          }
        }
      ) if defined $fattr;
    } #/ for my $name ( sort { $FIELDS...})
  } #/ if ( exists $fields::attr...)
  return @fields;
}

# Returns the local fields (without the inherited from parents) for the 
# specified target
sub slots {    # @metafields ($target)
  my $proto = shift;
  assert ( $proto );
  my $target = ref $proto || $proto;
  my @fields;
  if ( exists $fields::attr{$target} ) {
    # The following code is taken from fields::_dump()
    no strict 'refs';
    my %FIELDS = %{"$target\::FIELDS"};
    for my $name ( sort { $FIELDS{$a} <=> $FIELDS{$b} } keys %FIELDS ) {
      my $no    = $FIELDS{$name} || next;
      my $fattr = $fields::attr{$target}[$no];
      # we only want to have the newly defined %FIELDS of $target
      if ( defined $fattr && !( $fattr & fields::INHERITED ) ) {
        push(
          @fields,
          {
            name        => $name,
            initializer => {
              is       => $target->can( $name ) ? 'bare' : 'rw',
              init_arg => $name,
            }
          }
        );
      } #/ if ( defined $fattr &&...)
    } #/ for my $name ( sort { $FIELDS...})
  } #/ if ( exists $fields::attr...)
  return @fields;
} #/ sub slots

# Checks if a field is defined for the specified target
sub has_slot {    # $bool ($target, $name)
  my ( $proto, $name ) = @_;
  assert( $proto );
  assert( $name && !ref $name );
  my $target = ref $proto || $proto;
  return
    unless exists $fields::attr{$target};
  no strict 'refs';
  my %FIELDS = %{"$target\::FIELDS"};
  my $no     = $FIELDS{$name} || return;
  my $fattr  = $fields::attr{$target}[$no];
  return defined $fattr;
}

# Returns an hash reference to represent the field of the given name, 
# if one exists. If not FALSE is returned.
sub get_slot {    # \%metafield ($target, $name)
  my ( $proto, $name ) = @_;
  assert( $proto );
  assert( $name && !ref $name );
  my $target = ref $proto || $proto;
  return
    unless exists $fields::attr{$target};
  no strict 'refs';
  my %FIELDS = %{"$target\::FIELDS"};
  my $no     = $FIELDS{$name} || return;
  my $fattr  = $fields::attr{$target}[$no];
  return
    unless defined $fattr;
  return {
    name => $name,
    initializer => {
      is       => $target->can($name) ? 'bare' : 'rw',
      init_arg => $name,
    },
  } 
}

# Adds new fields to the class. If no fields are specified, the defined fields 
# of target are used via 'slots' method.
sub install_slots {    # void ($target, | @fields)
  my ( $proto, @fields ) = @_;
  assert( $proto );
  my $target = ref $proto || $proto;
  unless ( @fields ) {
    # If no fields are specified, take the slots from $target.
  	push( @fields, $_->{name} ) for slots( $target );
  }
  return 
    unless @fields;

  # consideration of the different toolkit's
  if ( is_Moose ) {
    # Moose uses Class::MOP which we can use
    my $meta = $target->meta;
    foreach my $field ( @fields ) {
      if ( my $slot = get_slot( $target, $field ) ) {
        my $access = $slot->{initializer}{is};
        assert ( $access );
        $access ||= 'rw';
        $meta->add_attribute( $field => ( is => $access ) );
      }
    }
    $meta->make_immutable;
  }
  elsif ( is_Moo ) {
    # There is no meta object for Moo (by default).
    my $present = eval(qq[
      package $target;
      return exists &has;
    ]);
    unless ( $present ) {
      eval(qq[
        package $target;
        use Moo;
        return 1;
      ]) or Carp::confess($@ );
    }
    foreach my $field ( @fields ) {
      if ( my $slot = get_slot( $target, $field ) ) {
        my $access = $slot->{initializer}{is};
        assert ( $access );
        $access ||= 'rw';
        # eval helps to set Moo attributes using 'has'
        eval(qq[
          package $target;
          has $field => ( is => $access );
          return 1;
        ]) or Carp::confess($@ );
      }
    }
    unless ( $present ) {
      eval(qq[
        package $target;
        no Moo;
        return 1;
      ]) or Carp::confess($@ );
    }
  } 
  elsif ( is_ClassTiny ) {
    # Class::Tiny defines a class method for creating attributes
    require Class::Tiny;
    Class::Tiny->create_attributes( $target, @fields );
  } 
  else {
    # pragma fields and classic Perl OOP have no accessor generators
    foreach my $field ( @fields ) {
      if ( my $slot = get_slot( $target, $field ) ) {
        my $access = $slot->{initializer}{is};
        assert ( $access );
        $access ||= 'rw';
		    if ( $access ne 'bare' ) {
          no strict 'refs';
          my $fullname = "$target\::$field";
          *$fullname =
            $access eq 'ro'
            ? sub { 
                Carp::croak( $EINVAL ) if @_ > 1;
                $_[0]->{$field};
              }
            : sub { 
                $_[0]->{$field} = $_[1] if @_ > 1; 
                $_[0]->{$field};
              };
        }
      }
    }
  }

  return;
}

# Create a constructor for the specified target
sub create_constructor {    # void ($target, | $name)
  my ( $proto, $name ) = @_;
  assert( $proto );
  my $target = ref $proto || $proto;
  $name ||= 'new';

  # consideration of the different toolkit's
  if ( is_Moose ) {
    Carp::confess("'Moose' creates 'new' as default constructor")
      if $name ne 'new';
    # We use Moose::Meta::Class to create a class by specifying Moose::Object
    # as the parent from which we inherit new.
    require Moose::Meta::Class;
    Moose::Meta::Class->create( 
      $target, superclasses => ['Moose::Object'],
    );
  }
  elsif ( is_Moo ) {
    Carp::confess("'Moo' creates 'new' as default constructor")
      if $name ne 'new';
    # If Moo is loaded, TObject is a derivation of this Moo::Object and 
    # therefore also inherits the new method.
    eval(qq(
      package $target;
      use parent 'Moo::Object';
      return 1;
    )) or Carp::croak( $@ );
  }
  elsif ( is_ClassTiny ) {
    Carp::confess("'Class::Tiny::Object' creates 'new' as default constructor")
      if $name ne 'new';
    # If Class:Tiny is loaded, we use the class method to create the TObject. 
    # The new method is automatically inherited from Class::Tiny::Object.
    require Class::Tiny;
    Class::Tiny->prepare_class( $target );
  }
  else {
    # pragma fields and classic Perl OOP have no default constructor
    no strict 'refs';

    # The constructor for TObject is created as follows ..
    my $new = "$target\::$name";
    return    # constructor already exists
      if exists &$new;

    *$new = sub {    # $obj (@)
      my $self  = shift;
      my $class = ref $self || $self;
      my $args;
      if ( $class->can('BUILDARGS' ) ) {
        # If BUILDARGS exists, we use this ..
        $args = $class->BUILDARGS( @_ );
      } 
      else {
        # .. otherwise we take init_arg values as hashref or hash.
        if ( @_ == 1 && ref $_[0] ) {
          my $arg = shift;
          my $ref = ref $arg;
          Carp::confess( 'Unable to coerce to HASH reference from unknown '.
            "reference type ($ref)" ) 
              if ( reftype $arg || '' ) ne 'HASH';
          $args = $arg;
        } #/ if ( @_ == 1 && ref $_...)
        else {
          Carp::confess( 'Unable to coerce to HASH reference from LIST with '.
            'odd number of elements' ) 
              if @_ % 2 == 1;
          $args = +{ @_ };
        }
      }
      # bless $self, if not already done.
      # Take care whether pragma fields are set or classic Perl OOP is used.
      unless ( ref $self ) {
        $self = is_fields
              ? fields::new( $class )
              : bless {}, $class;
      }
      # All defined init_arg hash values are passed to $self
      map { $self->{$_} = $args->{$_} }
        grep { 
          $_ = $_->{initializer}{init_arg};
          defined( $_ ) && exists( $args->{$_} );
        } all_slots( $class );
      # Call all BUILD methods starting with TObject up to the derived classes.
      map {
        my $super = ref $_ || $_;
        my $build = "$super\::BUILD";
        $build->( $self, $args ) if exists( &$build )
      } reverse @{ mro::get_linear_isa( $class ) };
      return $self;
    }; #/ sub new

    # The destructor for TObject is created as follows ..
    my $DESTROY = "$target\::DESTROY";
    return    # destructor already exists
      if exists &$DESTROY;

    *$DESTROY = sub {
      my $self = $_[0];
      # Call all DEMOLISH methods starting with the derived classes.
      map {
        my $super    = ref $_ || $_;
        my $demolish = "$super\::DEMOLISH";
        $demolish->( $self ) if exists( &$demolish )
      } @{ mro::get_linear_isa( $class ) };
    };
  }

  return;
}

1
