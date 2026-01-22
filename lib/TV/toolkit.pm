package TV::toolkit;

use strict;
use warnings;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:BRICKPOOL';

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Import::Into;
use Module::Loaded;

BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }
BEGIN { require Devel::GlobalDestruction unless $] >= 5.014 }

our $name;
BEGIN {
  $name = STRICT ? 'fields' : 'Moos';
  foreach my $toolkit ( qw( fields Moo Moos Moose UNIVERSAL::Object ) ) {
    if ( Module::Loaded::is_loaded $toolkit ) {
      $name = $toolkit;
      last;
    }
  }

  sub is_fields    (){ $name eq 'fields'            }
  sub is_Moo       (){ $name eq 'Moo'               }
  sub is_Moos      (){ $name eq 'Moos'              }
  sub is_Moose     (){ $name eq 'Moose'             }
  sub is_UNIVERSAL (){ $name eq 'UNIVERSAL::Object' }
}

my %added = ();

sub import {
  my $caller = caller();
  return if $caller eq 'main';
  return if $^H{ __PACKAGE__ . "/$caller" };

  if ( is_Moose ) {
    require Moose;
    Moose->import::into( $caller );
  }
  elsif ( is_Moos ) {
    require Moos;
    Moos->import::into( $caller );
    _around_hook( $caller, has => \&_my_moos_has );
    _add_demolish( 'Moos::Object' ) unless $added{DEMOLISH}++;
  }
  elsif ( is_Moo ) {
    require Moo;
    Moo->import::into( $caller );
    _add_dump( 'Moo::Object' ) unless $added{dump}++;
  }
  else {
    require TV::toolkit::LOP;
    _init_class( $caller );
    _create_constructor( $caller );
    _install_slots( $caller );
    _import_extends( $caller );
    _add_dump( is_UNIVERSAL ? 'UNIVERSAL::Object' : 'UNIVERSAL' )
      unless $added{dump}++;
  }

  $^H{ __PACKAGE__ . "/$caller" } = $name;
} #/ sub import

sub unimport {
  my $caller = caller();
  return unless $^H{ __PACKAGE__ . "/$caller" };

  $^H{ __PACKAGE__ . "/$caller" } = 0;
}

sub extends {
  TV::toolkit::LOP->init( caller() )->extend_class( @_ );
}

# Adds a new slots keyword to the class. 
# If no name is specified, the name of is 'has'.
sub _install_slots {    # void ($target, | $name)
  my ( $proto, $name ) = @_;
  assert ( $proto );
  assert ( !defined $name or !ref $name );
  my $target = TV::toolkit::LOP->init( ref $proto || $proto );
  $target->have_accessors( $name || 'has' );
  return;
}

# Create a constructor for the specified target
sub _create_constructor {    # void ($target)
  my ( $proto ) = @_;
  assert ( $proto );
  my $target = TV::toolkit::LOP->init( ref $proto || $proto );
  $target->create_constructor();
  return;
}

sub _init_class {    # void ($target)
  my ( $proto ) = @_;
  assert ( $proto );
  my $target = TV::toolkit::LOP->init( ref $proto || $proto );
  $target->warnings_strict();
  return;
}

sub _import_extends {    # void ($target)
  my ( $proto ) = @_;
  assert ( $proto );
  my $target = ref $proto || $proto;
  my $me = TV::toolkit::LOP->init( __PACKAGE__ );
  $me->import_methods( $target => 'extends' );
  return;
}

# An around method modifier without checking of an existing method
sub _around_hook {    # void ($class, $name, \&code)
  my ( $class, $name, $code ) = @_;
  assert ( defined $class and !ref $class );
  assert ( defined $name and !ref $name );
  assert ( defined $code and ref $code eq 'CODE' );
  my $fullpkg = "${class}::${name}";
  my $orig    = \&{$fullpkg};
  if ( defined $orig ) {
    no strict 'refs';
    no warnings 'redefine';
    *{"${fullpkg}"} = sub { $code->( $orig, @_ ) };
  }
  return;
} #/ sub _around_hook

sub _my_moos_has {    # $return (\&orig, $self, @_)
  my ( $orig, $self, %args ) = @_;
  if ( exists $args{is} && $args{is} eq 'bare' ) {
    $args{is} = 'rw';
    $args{_skip_setup} = 1;
  }
  return $self->$orig( %args );
} #/ sub _my_moos_has

sub _add_dump {    # void ($target)
  my ( $proto ) = @_;
  assert ( $proto );
  my $target = ref $proto || $proto;
  _around_hook( $target, 
    dump => sub {
      no warnings 'once';
      my $orig = shift;
      my $self = shift;
      require Data::Dumper;
      local $Data::Dumper::Sortkeys = 1;
      local $Data::Dumper::Maxdepth = shift if @_;
      my $str = Data::Dumper::Dumper $self;
      $str =~ s/(^|\s)\$VAR\d+\b/$1'$self'/g;
      return $str;
    }
  );
  return;
}

sub _add_demolish {    # void ($target)
  my ( $proto ) = @_;
  assert ( $proto );
  my $target = ref $proto || $proto;
  _around_hook( $target, 
    DESTROY => sub {
      my $orig = shift;
      my $self = shift;
      assert ( $self );
      my $class = ref $self || $self;

      my $in_global_destruction = defined ${^GLOBAL_PHASE}
        ? ${^GLOBAL_PHASE} eq 'DESTRUCT'
        : Devel::GlobalDestruction::in_global_destruction();

      # Call all DEMOLISH methods starting with the derived classes.
      foreach ( @{ mro::get_linear_isa( $class ) } ) {
        no strict 'refs';
        my $demolish = *{$_.'::DEMOLISH'}{CODE};
        next unless $demolish;
        $self->$demolish( $in_global_destruction )
      }
      return;
    }
  );
  return;
}

1
