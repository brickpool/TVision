package slots::less;
# ABSTRACT: A simple pragma for managing slots of a UNIVERSAL::Object class.

use strict;
use warnings;
no strict 'refs';
no warnings 'once';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:BRICKPOOL';

require Carp;
require fields;

use constant XS => do { eval q[ use Class::XSAccessor ]; !$@ };

BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }

sub import {
  shift;
  my $pkg = caller(0);
  my %slots = @_;
  return 
    unless %slots 
    && $pkg->isa('UNIVERSAL::Object');

  # create %FIELDS via pragma 'fields'
  $_ = join ' ' => keys %slots;
  eval qq[
      package $pkg;
      use fields qw( $_ );
      return 1;
    ] or Carp::confess( $@ );

  # assign 'slots' to %HAS and create the accessor
  my $fields = \%{"${pkg}::FIELDS"};
  if ( %$fields ) {
    _add_slot( $pkg, $_, $slots{$_} )
      for sort { $fields->{$a} <=> $fields->{$b} } keys %slots;
  }

  $^H{'slots::less/%HAS'} = 1;
}

sub _add_slot {
  my ( $class, $name, $initializer ) = @_;

  my $fields = \%{"${class}::FIELDS"};
  my $no     = $fields->{$name}           || return;
  my $fattr  = $fields::attr{$class}[$no] || return;

  # create %HAS if necessary
  my $has = \%{"${class}::HAS"};
  unless ( %$has ) {
    %$has = ();
    for my $isa ( reverse @{ mro::get_linear_isa( $class ) } ) {
      %$has = ( %$has, %{"${isa}::HAS"} );
    }
  }

  # store key/value in %HAS
  $has->{$name} = ref $initializer eq 'CODE' 
                ? $initializer 
                : sub { };

  # create public accessors and use the XS version if available
  if ( $fattr & fields::PUBLIC() && !( $fattr & fields::INHERITED() ) ) {
    if ( XS ) {
      eval qq[
              use Class::XSAccessor
                class => '$class',
                accessors => { '$name' => '$name' };
              return 1;
            ] or Carp::confess( $@ );
    }
    else {
      my $subname = "${class}::${name}";
      *$subname = sub { $#_ ? $_[0]->{$name} = $_[1] : $_[0]->{$name} };
    }
  } #/ if ( $fattr & fields::PUBLIC...)

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

This is why this pragma was developed, which does not require L<MOP> 
distribution, but does require and supplement the perl core pragmas L<base> 
and L<fields>.

Similar to the L<slots> pragma, C<slot::less> declares individual fields and 
accessors for a class that based on L<UNIVERSAL::Object>.

When available, L<Class::XSAccessor> is used to generate the class accessors.

=head1 DEPENDENCIES

L<UNIVERSAL::Object>, L<Carp> and L<MRO::Compat> when using perl < v5.10.

=head1 SEE ALSO

L<slots>, L<fields>.

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
