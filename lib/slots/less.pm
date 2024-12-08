package slots::less;
# ABSTRACT: A simple pragma for managing slots of a UNIVERSAL::Object class.

use strict;
use warnings;
no strict 'refs';
no warnings 'once';

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:BRICKPOOL';

BEGIN { sub XS () { eval q[ use Class::XSAccessor ]; !$@ } }

BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }

sub import {
  shift; # me
  my $caller = caller(0);

  # Only if UNIVERSAL::Object was used as the base class
  if ( $caller->isa( 'UNIVERSAL::Object' ) ) {
    # initialize %HAS variable
    _init_has( $caller );

    # assign 'slots' to %HAS and create the accessor
    if ( @_ ) {
      my %slots  = @_;
      my @fields = do { my $i; grep { not $i++ % 2 } @_ };
      _add_slot( $caller, $_, $slots{$_} ) for @fields;
    }
  } #/ if ( $caller->isa( 'UNIVERSAL::Object'...))

  $^H{'slots::less/%HAS'} = 1;
}

sub _init_has {
  my ( $class ) = @_;

  # %HAS should only be created if necessary
  my $HAS = \%{"${class}::HAS"};
  unless ( %$HAS ) {
    %{"${class}::HAS"} = ();
    $HAS = \%{"${class}::HAS"};
    for my $isa ( reverse @{ mro::get_linear_isa( $class ) } ) {
      if ( my $isa_HAS = \%{"${isa}::HAS"} ) {
        map { $HAS->{$_} = $isa_HAS->{$_} } keys %$isa_HAS;
      }
    }
  }

  return;
} #/ sub _init_has

sub _add_slot {
  my ( $class, $name, $initializer ) = @_;

  # store key/value in %HAS
  my $HAS = \%{"${class}::HAS"};
  $HAS->{$name} = ref $initializer eq 'CODE'
                ? $initializer
                : sub { };

  # create the accessor and use the XS version if available
  unless ( $class->can($name) ) {
    if ( XS ) {
      require Carp;
      eval qq[
              use Class::XSAccessor
                class => '$class',
                accessors => { '$name' => '$name' };
              return 1;
            ] or Carp::confess( $@ );
    }
    else {
      no warnings 'redefine';
      my $full_name = "${class}::${name}";
      *$full_name = sub { $#_ ? $_[0]->{$name} = $_[1] : $_[0]->{$name} };
    }
  }
  return;
}

sub unimport {
  $^H{'slots::less/%HAS'} = 0;
}

1;

__END__

=pod

=head1 NAME

slots::less - A simple pragma for UNIVERSAL::Object without MOP dependency

=head1 VERSION

version 0.01

=head1 DESCRIPTION

L<UNIVERSAL::Object> is a wonderful base class. The author I<Stevan Little> has 
added the pragma L<slots> for practical use, which is based on the L<MOP> 
distribution. In my opinion, this combination made the usage not as 
I<light-footed> as originally started. 

This is why this pragma was developed, which does not require the L<MOP> 
distribution.

Similar to the L<fields> pragma, C<slot::less> declares individual fields 
(stored in a global variable %HAS) and create accessors if a class based 
L<UNIVERSAL::Object> is in use.

When available, L<Class::XSAccessor> is used to generate the class accessors.

=head1 DEPENDENCIES

L<UNIVERSAL::Object> and L<MRO::Compat> when using perl < v5.10.

=head1 SEE ALSO

L<fields>, L<slots>.

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
