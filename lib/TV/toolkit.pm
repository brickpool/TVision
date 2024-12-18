package TV::toolkit;

use strict;
use warnings;

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use TV::toolkit::LOP;

our $name;
BEGIN {
  *name = *{TV::toolkit::LOP::name}{SCALAR};

  sub is_fields    (){ $name eq 'fields'            }
  sub is_UNIVERSAL (){ $name eq 'UNIVERSAL::Object' }
  sub is_ClassTiny (){ $name eq 'Class::Tiny'       }
  sub is_Moo       (){ $name eq 'Moo'               }
  sub is_Moose     (){ $name eq 'Moose'             }
}

sub import {
  my $caller = caller();
  return if $^H{"TV::toolkit/$caller"};

  init_class( $caller );
  create_constructor( $caller );
  install_slots( $caller );
  import_extends( $caller );

  $^H{"TV::toolkit/$caller"} = $name;
}

sub unimport {
  my $caller = caller();
  return unless $^H{"TV::toolkit/$caller"};

  # delete the slots method injected via import 
  my $target = TV::toolkit::LOP->init( $caller );
  if ( $target && $target->method_exists( 'slots' ) ) {
    $target->delete_method( 'slots' );
  }

  # if there is a Class::MOP object, 
  # it is Moose and we should make the class immutable.
  if ( __PACKAGE__->can( 'meta' ) ) {
    __PACKAGE__->meta->make_immutable;
  }

  $^H{"TV::toolkit/$caller"} = 0;
}

sub extends {
  TV::toolkit::LOP->init( caller() )->extend_class( @_ );
}

# Returns all fields (including the inherited from parents) for the specified 
# target
sub all_slots {    # @metafields ($target)
  my $proto = shift;
  assert ( $proto );
  my $target = TV::toolkit::LOP->init( ref $proto || $proto );
  my %FIELDS = %{ $target->get_attributes() };
  for my $pkg ( reverse ( $target->superclasses() ) ) {
    my $meta = TV::toolkit::LOP->init( $pkg );
    %FIELDS = ( %FIELDS, %{ $meta->get_attributes() } );
  }
  return map { { name => $_, initializer => $FIELDS{$_} } } sort keys %FIELDS;
}

# Returns the local fields (without the inherited from parents) for the 
# specified target
sub slots {    # @metafields ($target)
  my $proto = shift;
  assert ( $proto );
  my $target = TV::toolkit::LOP->init( ref $proto || $proto );
  my $fields = $target->get_attributes();
  return map { { name => $_, initializer => $fields->{$_} } } 
    sort keys %$fields;
} #/ sub slots

# Checks if a field is defined for the specified target
sub has_slot {    # $bool ($target, $name)
  my ( $proto, $name ) = @_;
  assert( $proto );
  assert( $name && !ref $name );
  my $target = TV::toolkit::LOP->init( ref $proto || $proto );
  my $fields = $target->get_attributes();
  return exists $fields->{$name};
}

# Returns an hash reference to represent the field of the given name, 
# if one exists. If not FALSE is returned.
sub get_slot {    # \%metafield ($target, $name)
  my ( $proto, $name ) = @_;
  assert( $proto );
  assert( $name && !ref $name );
  my $target = TV::toolkit::LOP->init( ref $proto || $proto );
  my %FIELDS = %{ $target->get_attributes() };
  for my $pkg ( reverse ( $target->superclasses() ) ) {
    my $meta = TV::toolkit::LOP->init( $pkg );
    %FIELDS = ( %FIELDS, %{ $meta->get_attributes() } );
  }
  return unless exists $FIELDS{$name};
  return { name => $name, initializer => $FIELDS{$name} };
}

# Adds a new fields keyword to the class. 
# If no name is specified, the name of is 'slots'.
sub install_slots {    # void ($target, | $name)
  my ( $proto, $name ) = @_;
  assert( $proto );
  assert( !defined $name or !ref $name );
  my $target = TV::toolkit::LOP->init( ref $proto || $proto );
  $target->have_accessors( $name || 'slots' );
  return;
}

# Create a constructor for the specified target
sub create_constructor {    # void ($target)
  my ( $proto ) = @_;
  assert( $proto );
  my $target = TV::toolkit::LOP->init( ref $proto || $proto );
  $target->create_constructor();
  return;
}

sub init_class {    # void ($target)
  my ( $proto ) = @_;
  assert( $proto );
  my $target = TV::toolkit::LOP->init( ref $proto || $proto );
  $target->warnings_strict();
  return;
}

sub import_extends {    # void ($target)
  my ( $proto ) = @_;
  assert( $proto );
  my $target = ref $proto || $proto;
  my $me = TV::toolkit::LOP->init( __PACKAGE__ );
  $me->import_methods( $target, qw( extends ) );
  return;
}

1;
