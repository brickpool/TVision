package TV::toolkit;

use strict;
use warnings;

our $VERSION   = '0.07';
our $AUTHORITY = 'cpan:BRICKPOOL';

use autodie::Scope::Guard ();
use Carp                  ();
use Devel::StrictMode;
use Import::Into;
use Module::Loaded        ();
use PerlX::Assert::PP;

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

our %ADDED = ();

sub import {
  my $caller = caller();
  return if $caller eq 'main';
  return if $^H{ __PACKAGE__ . "/$caller" };

  if ( is_Moose ) {
    require Moose;
    Moose->import::into( $caller );
  }
  elsif ( is_Moo ) {
    require Moo;
    Moo->import::into( $caller );
  }
  elsif ( is_Moos ) {
    require Moos;
    Moos->import::into( $caller );
    _around_hook( $caller, has => \&_my_moos_has );
    _add_demolish( 'Moos::Object' ) unless $ADDED{DEMOLISH}++;
  }
  else {
    require TV::toolkit::LOP;
    _init_class( $caller );
    _create_constructor( $caller );
    _install_has( $caller );
    _import_extends( $caller );
  }

  $^H{ __PACKAGE__ . "/$caller" } = autodie::Scope::Guard->new(sub {
    _add_dump( $caller ) unless $caller->can( 'dump' );
  });
} #/ sub import

sub unimport {
  my $caller = caller();
  return unless $^H{ __PACKAGE__ . "/$caller" };
  if ( is_Moose ) {
    Moose->unimport::out_of( $caller );
  }
  elsif ( is_Moo ) {
    Moo->unimport::out_of( $caller );
  }
  elsif ( is_Moos ) {
    Moos->unimport::out_of( $caller );
    _delete_method( $caller, $_ ) for qw( has extends with );
  } 
  else {
    _delete_method( $caller, $_ ) for qw( has extends );
  }
  $^H{ __PACKAGE__ . "/$caller" } = 0;
}

sub extends {
  TV::toolkit::LOP->init( caller() )->extend_class( @_ );
}

# Adds the 'has' keyword to the class
sub _install_has {    # void ($target)
  my ( $proto, $name ) = @_;
  assert { $proto };
  my $target = TV::toolkit::LOP->init( ref $proto || $proto );
  $target->have_accessors( 'has' );
  return;
}

# Create a constructor for the specified target
sub _create_constructor {    # void ($target)
  my ( $proto ) = @_;
  assert { $proto };
  my $target = TV::toolkit::LOP->init( ref $proto || $proto );
  $target->create_constructor();
  return;
}

sub _init_class {    # void ($target)
  my ( $proto ) = @_;
  assert { $proto };
  my $target = TV::toolkit::LOP->init( ref $proto || $proto );
  $target->warnings_strict();
  return;
}

# Injects 'extends' keyword to the class
sub _import_extends {    # void ($target)
  my ( $proto ) = @_;
  assert { $proto };
  my $target = ref $proto || $proto;
  my $me = TV::toolkit::LOP->init( __PACKAGE__ );
  $me->import_methods( $target => 'extends' );
  return;
}

# Adds a new method to an existing class
sub _create_method {    # void ($class, $name, \&code)
  my ( $class, $name, $code ) = @_;
  assert { defined $class and !ref $class };
  assert { defined $name and !ref $name };
  assert { defined $code and ref $code eq 'CODE' };

  no strict 'refs';
  unless ( %{"${class}::"} ) {
    warn "Can't create ${name} in ${class}, because ${class} does not exist\n";
    return;
  }
  *{"${class}::${name}"} = $code;
  return;
} #/ sub _create_method

# Remove symbol slot from class
sub _delete_method {    # void ($class, $name)
  my ( $class, $name ) = @_;
  assert { defined $class and !ref $class };
  assert { defined $name and !ref $name };

  no strict 'refs';
  if ( exists ${"${class}::"}{$name} ) {
    delete ${"${class}::"}{$name};
  }
  return;
} #/ sub _delete_method

# An around method modifier without checking of an existing method
sub _around_hook {    # void ($class, $name, \&code)
  my ( $class, $name, $code ) = @_;
  assert { defined $class and !ref $class };
  assert { defined $name and !ref $name };
  assert { defined $code and ref $code eq 'CODE' };

  my $orig = $class->can($name);
  unless ( $orig ) {
    warn "${class}::${name}: cannot wrap non-existing method\n";
    return;
  }

  no strict 'refs';
  no warnings 'redefine';
  *{"${class}::${name}"} = sub { $code->( $orig, @_ ) };
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
  assert { $proto };
  my $target = ref $proto || $proto;
  _create_method( $target, 
    dump => sub {
      no warnings 'once';
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
  assert { $proto };
  my $target = ref $proto || $proto;
  return if $target->can( 'DESTROY' );
  _create_method( $target, 
    DESTROY => sub {
      my $self = shift;
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

__END__

=pod

=head1 NAME

TV::toolkit - Unified OO facade using Moos/Moo/Moose when available

=head1 SYNOPSIS

  package Point;
  use TV::toolkit;

  has x => ( is => 'rw' );
  has y => ( is => 'rw' );

  no TV::toolkit;  # remove keywords (has, extends)
                   # keep methods (new, dump, DESTROY)

  my $p = Point->new( x => 1, y => 2 );
  say $p->dump;

=head1 DESCRIPTION

C<TV::toolkit> is a lightweight object system facade which automatically
selects an available OO toolkit in the following priority:

=over 4

=item * C<Moos> (if loaded)

=item * C<Moo>  (if loaded)

=item * C<Moose> (if loaded)

=item * otherwise: a minimal LOP fallback provided by TV::toolkit itself

=back

The selection is made at compile time for each caller of C<use TV::toolkit>.
Whichever toolkit is active, C<TV::toolkit> installs a consistent set of
keywords and behaviors, including:

=over 4

=item * C<has> – attribute declaration

=item * C<extends> – simple class inheritance

=item * an optional C<dump> method, unless already present

=item * a C<DESTROY> method that dispatches C<DEMOLISH> in MRO order

=back

The goal is to provide a predictable minimum OO feature set regardless of
which backend toolkit is already in use.

=head1 BACKEND BEHAVIOR

If any of these toolkits are already loaded, C<TV::toolkit> uses them
directly:

=over 4

=item * C<Moos> – primary minimal backend (defaults to this when available)

=item * C<Moo> – lightweight attribute and method generator

=item * C<Moose> – full meta-object system

=back

No attempt is made to replace or extend the backend beyond injecting
C<dump> and C<DESTROY> when appropriate.

If none of Moos/Moo/Moose are loaded, a very small I<LOP style> OO layer is 
used. 

This exists only to keep modules functional in environments where no of the 
other toolkits are available. It is not intended to be a full object system.

=head1 SEE ALSO

=over 4

=item * L<Moos>

=item * L<Moo>

=item * L<Moose>

=item * L<Devel::StrictMode>

=back

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 LICENSE

Copyright (c) 2024-2026 the L</AUTHORS> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
