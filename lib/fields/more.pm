package fields::more;
# ABSTRACT: A simple pragma for managing slots of a UNIVERSAL::Object class.

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:BRICKPOOL';

require Carp;
require fields;

BEGIN { sub XS () { eval q[ use Class::XSAccessor ]; !$@ } }

BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }

sub import {
  shift; # me
  my $caller = caller(0);

  # initialize %FIELDS variable
  _init_fields( $caller, @_ );

  # Only if UNIVERSAL::Object was used as the base class
  if ( $caller->isa( 'UNIVERSAL::Object' ) ) {
    my %slots = map { $_ => sub { } } @_;
    my @fields = @_;

    _modify_fields_ctor( $caller );
    _modify_fields_attr( $caller, \%slots );

    _init_SLOTS( $caller );
    _add_accessor( $caller, $_, \%slots ) for @fields;
  } #/ if ( $caller->isa( 'UNIVERSAL::Object'...))

  $^H{'fields::more/%FIELDS'} = 1;
}

sub _init_fields {    # void ($class)
	my $class  = shift;
	my $fields = join ' ' => @_;

	# call fields pragma
	eval qq[
    package $class;
    use fields qw( $fields );
    return 1;
  ] or Carp::croak( $@ );

	return;
} #/ sub _init_fields

# Overwrite the new constructor of the field pragma.
sub _modify_fields_ctor {    # void ($class)
  my ( $class ) = @_;

  # &fields::new should point to UNIVERSAL::BLESS (or the overwritten version)
  no strict 'refs';
  if ( *{'fields::new'}{CODE} ) {
    my $BLESS = *{"${class}::BLESS"}{CODE};
    foreach my $super ( @{ mro::get_linear_isa( $class ) } ) {
      last if $BLESS;
      $BLESS = *{"${super}::BLESS"}{CODE};
    }
    no warnings 'redefine';
    *{'fields::new'} = $BLESS ? $BLESS : *{'UNIVERSAL::Object::BLESS'}{CODE};
  }

  return;
} #/ sub _modify_fields_ctor

# assign 'slots' to %FIELDS and create the accessors
sub _modify_fields_attr {    # void ($class, $slots)
  my ( $class, $slots ) = @_;

  # %FIELDS should point to a Slot object
  require fields::more::Slot;
  require overload;
  foreach my $super ( reverse @{ mro::get_linear_isa( $class ) } ) {
    no strict 'refs';
    no warnings 'once';
    my $fields = *{"${super}::FIELDS"}{CODE} || {};
    foreach my $name ( keys %$fields ) {
      next unless $fields->{$name};
      next if overload::Method($fields->{$name}, '&{}');
      $fields->{$name} = fields::more::Slot->new(
        default => $slots->{$name} || sub {},
        no      => $fields->{$name},
      );
    }
  }

  return;
} #/ sub _init_fields

# Assigning or modifying the SLOTS method in the caller
sub _init_SLOTS {
	my ( $class ) = @_;

  my $body;
  no strict 'refs';
  no warnings 'once';
  if ( *{"${class}::SLOTS"}{CODE} ) {
    $body = q[
      no strict 'refs';
      no warnings 'redefine';
      my $orig = \&SLOTS;
      *SLOTS = sub {
        my $class = ref $_[0] || $_[0];
        my %slots = $orig->(@_);
        foreach ( keys %slots ) {
          next if overload::Method( $slots{$_}, '&{}' );
          next if ref $slots{$_} eq 'CODE';
          next if $slots{$_} && $slots{$_} =~ /^[1-9]\d+/;
          $slots{$_} = sub {};
        }
        return %slots;
      };
    ];
  }
  else {
    $body = q[
      no strict 'refs';
      *SLOTS = sub {
        my $class = ref $_[0] || $_[0];
        my %slots = $class->SUPER::SLOTS( @_ );
        foreach ( keys %slots ) {
          next if overload::Method( $slots{$_}, '&{}' );
          next if ref $slots{$_} eq 'CODE';
          next if $slots{$_} && $slots{$_} =~ /^[1-9]\d+/;
          $slots{$_} = sub {};
        }
        return %slots;
      };
    ];
  }

  eval qq[
    package $class;
    CHECK { $body }
    return 1;
  ] or Carp::croak( $@ );

  return;
}

sub _add_accessor {    # void ($class, $name, $slots)
  my ( $class, $name ) = @_;

  # create/override the accessor and use the XS version if available
  unless ( $class->can($name) ) {
    if ( XS ) {
      eval qq[
        use Class::XSAccessor
          class => '$class',
          accessors => { '$name' => '$name' };
        return 1;
      ] or Carp::croak( $@ );
    }
    else {
      my $full_name = "${class}::${name}";
      *$full_name = sub { $#_ ? $_[0]->{$name} = $_[1] : $_[0]->{$name} };
    }
  }
  return;
}

sub unimport {
  $^H{'fields::more/%FIELDS'} = 0;
}

1;

BEGIN {
  package fields::more::Slot;
  use strict;
  use warnings;

  use overload
    '&{}' => 'to_code',
    '0+'  => 'to_num';

  sub new {
    my ( $class, %args ) = @_;
    return unless ref $args{default} eq 'CODE';
    return unless $args{no} && $args{no} =~ /^\d+$/;
    bless {%args} => $class;
  }

  sub to_code {
    my ( $self ) = @_;
    sub { $self->{default}->( @_ ) };
  }

  sub to_num {
    $_[0]->{no};
  }

  $INC{"fields/more/Slot.pm"} = 1;
}

__END__

=pod

=head1 NAME

fields::more - A simple pragma for UNIVERSAL::Object without MOP dependency

=head1 VERSION

version 0.01

=head1 DESCRIPTION

L<UNIVERSAL::Object> is a wonderful base class. The author I<Stevan Little> has 
added the pragma L<slots> for practical use, which is based on the L<MOP> 
distribution. In my opinion, this combination made the usage not as 
I<light-footed> as originally started. 

This is why this pragma was developed, which does not require the L<MOP> 
distribution.

Similar to the L<fields> pragma, C<fields::more> declares individual fields 
(stored in a global variable %FIELDS) and create accessors if a class based 
L<UNIVERSAL::Object> is in use.

When available, L<Class::XSAccessor> is used to generate the class accessors.

=head1 DEPENDENCIES

L<Carp>, L<fields>, L<UNIVERSAL::Object> and L<MRO::Compat> when using 
perl < v5.10.

=head1 BUGS, CAVETS

This pragma creates the global variable C<%FIELDS> used by 
C<UNIVERSAL::Objects>. This means that all derived classes will require 
C<%FIELDS> (including inherited entries), even if no new I<slots> are added. 

The simplest way to achieve this is by consistently using C<use fields::more;>. 
The import routine creates the global variable C<%FIELDS> and initializes the 
necessary entries.

=head1 SEE ALSO

L<fields>, L<slots>.

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
