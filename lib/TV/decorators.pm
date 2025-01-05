package TV::decorators;

use strict;
use warnings;

use autodie::Scope::Guard ();
use Carp                  ();
use Exporter              ();
use Scalar::Util          ();
use Sub::Util             ();

our $VERSION   = '0.01';
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

sub FETCH_CODE_ATTRIBUTES {
	my ( $class, $coderef ) = @_;

	# return just the strings, as expected by attributes ...
	return $ATTRS{ "$coderef" } ? @{ $ATTRS{ "$coderef" } } : ();
}

sub MODIFY_CODE_ATTRIBUTES {
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

sub static {
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

sub instance {
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

=head1 DEPENDENCIES

This module depends on the following modules:

=over

=item *

autodie::Scope::Guard

=item *

Carp

=item *

Exporter

=item *

Scalar::Util

=item *

Sub::Util

=back

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

=cut
