package TV::toolkit::decorators;
# ABSTRACT: Apply decorators to your subs.

# Prior to Perl 5.15.4, attribute handlers are executed before the body is 
# attached, so see it in that intermediate state. (From Perl 5.15.4 onwards, 
# attribute handlers are executed after the body is attached.
# See: L<Sub::WhenBodied> for details.
use 5.015004;
use strict;
use warnings;

use autodie::Scope::Guard ();
use Carp                  ();
use Exporter              ();
use Scalar::Util          ();
use Sub::Util             ();

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:BRICKPOOL';

our @EXPORT = qw(
  MODIFY_CODE_ATTRIBUTES
  FETCH_CODE_ATTRIBUTES
);

our %ATTRS;    # package variable to store attribute lists by coderef (address)

sub import {
  my $caller = caller();
  return if $caller eq 'main';

  # The following tests are taken from L<decorators>.
  Carp::confess( 
      'Cannot install decorator collectors, '
    . 'MODIFY_CODE_ATTRIBUTES method already exists'
  ) if $caller->can( 'MODIFY_CODE_ATTRIBUTES' );

  Carp::confess(
      'Cannot install decorator collectors, '
    . 'FETCH_CODE_ATTRIBUTES method already exists'
  ) if $caller->can( 'FETCH_CODE_ATTRIBUTES' );

  # Attribute names in lowercase are reserved
  warnings->unimport('reserved') if warnings::enabled('reserved');

  # Cleanup at the end of a scope
  $^H{ __PACKAGE__ . "/$caller" } = autodie::Scope::Guard->new(
    sub {
      no strict 'refs';
      undef( *{"${caller}::MODIFY_CODE_ATTRIBUTES"} )
          if *{"${caller}::MODIFY_CODE_ATTRIBUTES"}{CODE};
      undef( *{"${caller}::FETCH_CODE_ATTRIBUTES"} )
          if *{"${caller}::FETCH_CODE_ATTRIBUTES"}{CODE};
    }
  );

  # export MODIFY_CODE_ATTRIBUTES and FETCH_CODE_ATTRIBUTES to caller
  goto &Exporter::import;
}

sub unimport {
  my $caller = caller();
  return unless $^H{ __PACKAGE__ . "/$caller" };

  $^H{ __PACKAGE__ . "/$caller" } = 0;
}

sub FETCH_CODE_ATTRIBUTES {    # @attrs ($class, $coderef)
  my ( $class, $coderef ) = @_;

  # return just the strings, as expected by attributes ...
  return $ATTRS{ "$coderef" } ? @{ $ATTRS{ "$coderef" } } : ();
}

sub MODIFY_CODE_ATTRIBUTES {    # @disallowed|undef ($package, $coderef, @attributes, @disallowed)
  my ( $package, $coderef, @attributes, @disallowed ) = @_;
  push @disallowed,
    grep { 
      /^(?:
        import | unimport | FETCH_CODE_ATTRIBUTES | MODIFY_CODE_ATTRIBUTES
      )$/x
      or not __PACKAGE__->can( $_ ) 
    } @attributes;

  # return the bad decorators as strings, as expected by attributes ...
  return @disallowed if @disallowed;

  # process the attributes ...
  foreach my $attribute ( @attributes ) {
    my $d = __PACKAGE__->can( $attribute ) or die;
    $d->( $package, Sub::Util::subname( $coderef ), $coderef );
  }

  $ATTRS{ "$coderef" } = \@attributes;
  return;
} #/ sub MODIFY_CODE_ATTRIBUTES

sub static {    # ($package, $symbol, $referent)
  my ( $package, $symbol, $referent ) = @_;
  no strict 'refs';
  no warnings 'redefine';
  *{$symbol} = sub {
    # The following tests are taken from L<Method::Assert>.
    Carp::confess( "Method invoked as a function" )
      if @_ == 0;
    Carp::confess( "Class method invoked as an instance method" )
      if Scalar::Util::blessed $_[0];
    Carp::confess( "Invocant is a reference, not a simple scalar value" )
      if ref $_[0];
    Carp::confess("Invocant ". $_[0] . " is not a subclass of '$package'")
      unless $_[0]->isa($package);
    goto &$referent;
  };
} #/ sub _class_method

sub instance {    # ($package, $symbol, $referent)
  my ( $package, $symbol, $referent ) = @_;
  no strict 'refs';
  no warnings 'redefine';
  *{$symbol} = sub {
    # The following tests are taken from L<Method::Assert>.
    Carp::confess( "Method invoked as a function" )
      if @_ == 0;
    Carp::confess( "Method not invoked as an instance method" )
      unless Scalar::Util::blessed $_[0];
    Carp::confess("Invocant of class '" . ref( $_[0] ) . 
      "' is not a subclass of '$package'" )
        unless $_[0]->isa( $package );
    goto &$referent;
  };
} #/ sub _instance_method

1;

__END__

=head1 NAME

Apply decorators to your subs.

=head1 DESCRIPTION

This module manages attributes that can be attached to subroutine declarations.

=head1 REQUIRES

L<5.015004> 

L<autodie::Scope::Guard> 

L<Carp> 

L<Exporter> 

L<Scalar::Util> 

L<Sub::Util> 

=head2 FETCH_CODE_ATTRIBUTES

  my @attrs = FETCH_CODE_ATTRIBUTES($class, $coderef);

=head2 MODIFY_CODE_ATTRIBUTES

  my @disallowed | undef = MODIFY_CODE_ATTRIBUTES($package, $coderef, 
    @attributes, @disallowed);

=head2 import

  import();

=head2 instance

  instance($package, $symbol, $referent);

=head2 static

  static($package, $symbol, $referent);

=head2 unimport

  unimport();

=head1 BUGS AND LIMITATIONS

On older versions of Perl some of the necessary infrastructure is missing.

=head1 SEE ALSO

=over

=item *

L<Attribute::Lexical>

=item *

L<Attribute::Method>

=item *

L<Attribute::Static>

=item *

L<decorators>

=item *

L<Sub::Attributes>

=back

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 CONTRIBUTORS

Stevan Little <stevan@cpan.org>

=head1 LICENSE

Copyright (c) 2024-2025 the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
