=pod

=head1 NAME

TV::Objects::Object - defines the class TObject

=cut

package TV::Objects::Object;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TObject
);

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );
use mro ();

use TV::Util;

sub TObject() { __PACKAGE__ }

use fields qw();

my $EINVAL = do {
  require Errno;
  local $! = 1;
  $! = &Errno::EINVAL if exists &Errno::EINVAL;
  "$!";
};

sub DESTROY {    # void ($self)
  assert ( blessed shift );
  return;
}

sub destroy {    # void ($class|$self, $o|undef)
  my $class = shift;
  assert ( $class );
  if ( defined $_[0] ) {
    assert ( blessed $_[0] );
    $_[0]->shutDown();
    undef $_[0];
  }
  return;
}

sub shutDown {    # void ($self)
  assert ( blessed shift );
  return;
}

my $_make_constructor = sub {
  my ( $this, $name ) = @_;
  my $target = ref $this || $this;
  $name ||= 'new';

  # consideration of the different toolkit's
  if ( TV::toolkit::Moose || TV::toolkit::Moo ) {
    my $toolkit = $TV::Util::toolkit;
    Carp::confess("'$toolkit' creates 'new' as default constructor")
      if $name ne 'new';
    # If a toolkit is loaded, TObject is a derivation of this base object and 
    # therefore also inherits the new method
    eval(qq(
      package $target;
      use parent '$toolkit\::Object';
      return 1;
    )) or Carp::croak( $@ );
  }
  elsif ( TV::toolkit::ClassTiny ) {
    Carp::confess("'Class::Tiny::Object' creates 'new' as default constructor")
      if $name ne 'new';
    # If Class:Tiny is loaded, we use the class method to create the TObject. 
    # The new method is automatically inherited from Class::Tiny::Object
    require Class::Tiny;
    Class::Tiny->prepare_class( $target );
  }
  else {
    # pragma fields and classic Perl OOP have no default contructor
    no strict 'refs';
    my $fullname = "$target\::$name";
    return    # constructor already exists
      if exists &$fullname;
    # The constructor for TObject is created as follows ..
    *$fullname = sub {    # $obj (@)
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
        $self = TV::toolkit::fields
              ? fields::new( $class )
              : bless {}, $class;
      }
      # All existing init_arg hash values are passed to $self
      my %fields = map { $_ => 1 } fields::_accessible_keys( $class );
      map { $self->{$_} = $args->{$_} } grep { $fields{$_} } keys %$args;
      # Call all BUILD methods starting with TObject up to the derived classes.
      map {
        my $pkg   = ref $_ || $_;
        my $build = "$pkg\::BUILD";
        $build->( $self, $args ) if exists( &$build )
      } reverse @{ mro::get_linear_isa( $class ) };
      return $self;
    }; #/ sub new
  }

  return;
};

my $_mk_accessors = sub {
  my ( $this, $access, @fields ) = @_;
  # $target can be object or class
  my $target = ref $this || $this;
  # set 'rw' if no access type is specified 
  $access ||= 'rw';
  # If no fields are specified, read the %FIELDS variable from $target.
  unless ( @fields ) {
    require base;
    if ( base::has_attr( $target ) ) {
     # The following code is taken from fields::_dump()
      no strict 'refs';
      my %FIELDS = %{"$target\::FIELDS"};
      for my $field ( sort { $FIELDS{$a} <=> $FIELDS{$b} } keys %FIELDS ) {
        my $no    = $FIELDS{$field};
        my $fattr = base::get_attr( $target )->[$no];
        # we only want to have the newly defined %FIELDS of $target
        push( @fields, $field )
          if defined( $fattr ) && !( $fattr & base::INHERITED );
      }
    } #/ if ( base::has_attr( $target...))
  }
  return 
    unless @fields;

  # consideration of the different toolkit's
  if ( TV::toolkit::Moose ) {
    # Moose uses Class::MOP which we can use
    my $meta = $target->meta;
    for my $field ( @fields ) {
      my $fullname = "$target\::$field";
      $meta->add_attribute(
        $field => ( is => exists &$fullname ? 'bare' : $access )
      );
    }
    $meta->make_immutable;
  }
  elsif ( TV::toolkit::Moo ) {
    eval(qq[
      package $target;
      use Moo;
      return 1;
    ]) or Carp::confess($@ );
    for my $field ( @fields ) {
      # eval helps to set Moo attributes using 'has'
      my $fullname = "$target\::$field";
      eval(qq[
        package $target;
        has $field => ( is => exists &$fullname ? 'bare' : '$access' );
        return 1;
      ]) or Carp::confess($@ );
    }
    eval(qq[
      package $target;
      no Moo;
      return 1;
    ]) or Carp::confess($@ );
  } 
  elsif ( TV::toolkit::ClassTiny ) {
    # Class::Tiny defines a class method for creating attributes
    require Class::Tiny;
    Class::Tiny->create_attributes( $target, @fields );
  } 
  else {
    # pragma fields and classic Perl OOP have no accessor generators
    for my $field ( @fields ) {
		  next    # Method with the same name already exists
        if $target->can( $field );
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

  return;
}; #/ $_mk_accessors = sub

sub mk_constructor {
  my $this = shift;
  $this->$_make_constructor( @_ );
  return $this;    # for chaining
}

sub mk_ro_accessors {
  my $this = shift;
  $this->$_mk_accessors( 'ro', @_ );
  return $this;
}

sub mk_rw_accessors {
  my $this = shift;
  $this->$_mk_accessors( 'rw', @_ );
  return $this;
}

{
  no warnings 'once';
  *mk_accessors = \&mk_rw_accessors;
}

__PACKAGE__->mk_constructor();

1
