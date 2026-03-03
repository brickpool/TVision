package TV::toolkit::Params;
# ABSTRACT: Lightweight positional argument validation inspired by Type::Params

use 5.010;
use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT_OK = qw(
  signature
);

use B::Deparse   ();
use Carp         ();
use Scalar::Util ();
use Sub::Util    ();

our @CARP_NOT;

my $DEPARSE = B::Deparse->new( "-P", "-sC" );

sub coderef2text {
  my ( $code ) = @_;
  my $body = $DEPARSE->coderef2text( $code );
  for ( $body ) {
    s/^\h+(?:use|no) (?:strict|warnings|feature|integer|utf8|bytes|re)\b[^\n]*\n//gm;
    s/^\h+package [^\n]*;\n//gm;
    s/\A\{\n\h+([^\n;]*);\n\}\z/{ $1 }/;
  }
  return $body;
}

# Internal helper: compile a generic checker for a type
# The returned checker has the signature: ($value, $label) -> $value or croak
# $label is a string used in error messages (e.g. '$_[0]' or '$SLURPY').
sub compile_type_checker {
  my ( $type ) = @_;

  # Type::API-style object
  if ( Scalar::Util::blessed( $type ) && $type->can( 'check' ) ) {

    return sub {
      my ( $val, $label ) = @_;
      local $_ = $val;

      return $val if $type->check( $val );

      my $msg = $type->can( 'get_message' )
              ? $type->get_message( $val )
              : "Argument did not pass type constraint";

      Carp::croak( "$msg (in $label)" );
    };
  }

  # Plain CODE ref
  elsif ( ref $type && Scalar::Util::reftype( $type ) eq 'CODE' ) {
    my $name = Sub::Util::subname( $type );
    $name = coderef2text( $type )
      if $name && $name =~ /::__ANON__$/;

    return sub {
      my ( $val, $label ) = @_;
      local $_ = $val;

      return $val if $type->( $val );

      my $desc = !defined( $val ) ? "Undef"
               : ref( $val )      ? "Reference $val"
               :                    "Value \"$val\"";

      Carp::croak( "$desc did not pass type constraint $name (in $label)" );
    };
  }

  # Unsupported type specification
  else {
    return sub {
      my ( undef, $label ) = @_;
      Carp::croak( "Unsupported type definition for argument $label" );
    };
  }
}

sub signature {
  no warnings;    ## no critic (ProhibitNoWarnings)
  my ( %args ) = @_;

  # Get positional entry (accepts both 'pos' and 'positional'
  my @spec = @{
      exists $args{pos}        ? $args{pos}
    : exists $args{positional} ? $args{positional}
    :                            [] 
  };

  # Parse positional spec into internal parameter list:
  #   [ isa, { optional => 1, slurpy => 1 }, isa, ... ]
  my @params;
  while ( @spec ) {
    my $isa = shift @spec;
    my $opts = ( @spec && ref $spec[0] eq 'HASH' )
             ? shift @spec
             : {};
    push @params, {
      isa      => $isa,
      optional => $opts->{optional} ? 1 : 0,
      slurpy   => $opts->{slurpy}   ? 1 : 0,
    };
  }

  # There must be at least one parameter
  Carp::croak "Signature must be positional" unless @params;

  # Validate parameter ordering and detect slurpy
  my $seen_optional = 0;
  my $has_slurpy    = 0;
  my $slurpy_index  = -1;

  for my $idx ( 0 .. $#params ) {
    my $p = $params[$idx];
    if ( $p->{slurpy} ) {
      # Slurpy must be last and must be unique
      Carp::croak "Parameter following slurpy parameter"
        if $has_slurpy || $idx != $#params;

      Carp::croak "Slurpy parameter cannot be optional"
        if $p->{optional};

      $has_slurpy   = 1;
      $slurpy_index = $idx;
    }
    else {
      if ( $p->{optional} ) {
        $seen_optional = 1;
      }
      elsif ( $seen_optional ) {
        # Once an optional param has been seen, all following
        # non-slurpy params must also be optional.
        Carp::croak "Non-Optional parameter following Optional parameter";
      }
    }
  }

  # Separate fixed (non-slurpy) parameters
  my @fixed_params = grep { !$_->{slurpy} } @params;

  # Compute min and max arity for non-slurpy parameters
  my $min_arity = 0;
  my $max_arity = 0;
  foreach my $p ( @fixed_params ) {
    $max_arity++;
    $min_arity++ unless $p->{optional};
  }

  # Compile checkers for fixed parameters
  my @checks;
  for my $idx ( 0 .. $#fixed_params ) {
    my $type  = $fixed_params[$idx]{isa};
    my $check = compile_type_checker( $type );

    push @checks, sub {
      my ( $val ) = @_;
      return $check->( $val, "\$_[$idx]" );
    };
  }

  # Compile checker for slurpy parameter (if present)
  my $slurpy_check;
  if ( $has_slurpy ) {
    my $type    = $params[$slurpy_index]{isa};
    my $generic = compile_type_checker( $type );

    $slurpy_check = sub {
      my ( $aref ) = @_;
      return $generic->( $aref, '$SLURPY' );
    };
  }

  return sub {
    # Adjust Carp stack level so errors point to the caller of the signature
    local $Carp::CarpLevel = 2;

    my $argc = @_;

    # Arity checks
    my $too_few  = $argc < $min_arity;
    my $too_many = !$has_slurpy && $argc > $max_arity;

    if ( $too_few || $too_many ) {
      my $expected = $has_slurpy              ? "at least $min_arity"
                   : $min_arity == $max_arity ? "$min_arity"
                   :                            "$min_arity to $max_arity";

      Carp::croak "Wrong number of parameters; got $argc; expected $expected";
    }

    # Increase level for checks so error locations look natural
    $Carp::CarpLevel += 2;

    # Validate fixed (non-slurpy) positional arguments
    my $fixed_to_check = $argc < @checks ? $argc : @checks;
    $checks[$_]->( $_[$_] ) for 0 .. $fixed_to_check - 1;

    # If there is no slurpy parameter, just return original arguments.
    # Missing optional parameters will simply become undef.
    return @_ unless $has_slurpy;

    # Slurpy: arrayref of remaining args (empty is allowed)
    my $rest = [];
    if ( $argc > @checks ) {
      $rest = sub { \@_ }->( @_[ @checks .. $argc - 1 ] );
      $slurpy_check->( $rest );
    }

    # Return fixed values plus array ref for slurpy
    return ( @_[ 0 .. $#checks ], $rest );
  };

}

1

__END__

=pod

=head1 NAME

TV::toolkit::Params - Lightweight pure Perl positional argument validation

=head1 SYNOPSIS

  use TV::toolkit::Params qw( signature );
  use Type::Standard qw( ArrayRef Int );
  use Scalar::Util qw( looks_like_number );

  # Basic example
  sub add_numbers {
    state $sig = signature(
      pos => [
        Int,                 # Type::API / Type::Tiny compatible object
        sub { /^\d+$/ },     # custom CODE predicate
      ],
    );

    my ($x, $y) = $sig->(@_);
    return $x + $y;
  }

  say add_numbers(3, 5);      # ok
  say add_numbers(3, "abc");  # dies with descriptive error message

  # Example with slurpy parameter
  sub sum {
    state $sig = signature(
      pos => [
        Int,
        ArrayRef[Int], { slurpy => 1 },
      ],
    );

    my ($first, $rest) = $sig->(@_);   # $rest is an arrayref
    my $sum = $first;
    $sum += $_ for @$rest;
    return $sum;
  }

  say sum(1, 2, 3, 4);  # ok
  say sum(1, "x");      # dies with descriptive error

  # Example with optional parameters
  sub vector_length {
    state $sig = signature(
      pos => [
        \&looks_like_number,                      # x (mandatory)
        \&looks_like_number, { optional => 1 },   # y (optional)
        \&looks_like_number, { optional => 1 },   # z (optional)
      ],
    );

    my ($x, $y, $z) = $sig->(@_);

    # Missing optional components default to zero
    $y //= 0;
    $z //= 0;

    return sqrt($x*$x + $y*$y + $z*$z);
  }

  say vector_length(3, 4);       # 2D -> 5
  say vector_length(3, 4, 12);   # 3D -> 13

=head1 DESCRIPTION

The function C<signature> provides a lightweight mechanism for validating
positional arguments to Perl subroutines. It is inspired by L<Type::Params>,
but intentionally simpler and without dependencies on XS or Perl components 
that are not part of the standard distribution.

The module accepts a list of type specifications and returns a compiled
checker subroutine. This checker performs:

=over 4

=item *

Argument count validation, including optional and slurpy parameters.

=item *

Type validation via L<Type::API> compatible objects (providing C<check>
and C<get_message>).

=item *

Predicate validation via plain CODE references.

=item *

Helpful error messages including argument index or C<"$SLURPY">.

=back

All type checking logic is compiled once at signature creation time,
resulting in faster validation than doing checks inside the subroutine body.


=head1 OPTIONAL PARAMETERS

Optional parameters may be declared by attaching a hashref:

  pos => [
    Int,
    Str, { optional => 1 },
    Str, { optional => 1 },
  ]

Rules:

=over 4

=item *

Optional parameters must appear as one continuous block at the end of
the non-slurpy parameters.

=item *

A mandatory parameter after an optional parameter is an error:

  Non-Optional parameter following Optional parameter

=item *

Missing optional values are returned as C<undef>.

=back

=head1 SLURPY PARAMETER

A single slurpy parameter may be declared:

  pos => [
    Int,
    ArrayRef[Int], { slurpy => 1 },
  ]

Rules:

=over 4

=item *

The slurpy parameter must be the last entry in the C<pos> list.

=item *

Only one slurpy parameter is allowed.

=item *

All remaining arguments are collected into an arrayref and validated
as a single value.

=item *

Example return usage:

  my ($first, $rest) = $sig->(@_);
  my @values = @$rest;

=item *

If the slurpy parameter has a type constraint, it receives the arrayref
to validate.

=back

=head1 LIMITATIONS

This module implements only a subset of Type::Params. Notable limits:

=over 4

=item * Only positional parameters are supported.

No named parameters. Only C<pos> or C<position> are valid specifications.

=item * No coercions or automatic type conversions.

=item * No advanced parameter kinds

No parameter aliases, unions, parameter packs, or complex tuple types.

=item * No global caching.

Each subroutine must store its own C<state> variable.

=back

The goal is to provide a compact, dependency-light validation mechanism.

=head1 REQUIRES

Only core modules are used:

=over 4

=item * Perl 5.10+

=item * L<B::Deparse>

=item * L<Carp>

=item * L<Exporter>

=item * L<Scalar::Util>

=item * L<Sub::Util>

=back

=head1 SEE ALSO

=over 4

=item * L<Type::API::Constraint>

=item * L<Type::Params>

=item * L<Types::Standard>

=back

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 CONTRIBUTORS

Toby Inkster <tobyink@cpan.org>

=head1 LICENSE

Copyright (c) 2013-2014, 2017-2026 the L</AUTHORS> and L</CONTRIBUTORS> as 
listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
