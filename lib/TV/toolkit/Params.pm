package TV::toolkit::Params;
# ABSTRACT: Lightweight positional argument validation inspired by Type::Params

use 5.010;
use strict;
use warnings;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:BRICKPOOL';

use B::Deparse   ();
use Carp         ();
use Scalar::Util ();
use Sub::Util    ();

# ----------------------------------------------------------------------
# Exports
# ----------------------------------------------------------------------

use Exporter 'import';

our @EXPORT_OK = qw(
  signature
);



# ----------------------------------------------------------------------
# Public Subroutines
# ----------------------------------------------------------------------

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
  #   [ isa, { optional => 1, slurpy => 1, default => ... }, isa, ... ]
  my @params;
  while ( @spec ) {
    my $isa = shift @spec;
    my $opts = ( @spec && ref $spec[0] eq 'HASH' )
             ? shift @spec
             : {};

    my %param = (
      isa      => $isa,
      optional => $opts->{optional} ? 1 : 0,
      slurpy   => $opts->{slurpy}   ? 1 : 0,
    );

    # validate default
    if ( exists $opts->{default} ) {
      for ( $opts->{default} ) {
        last unless defined;      # undef is allowed
        last if ref eq 'CODE';    # CODE ref is allowed
        unless ( ref ) {          # non-ref must be pure PV
          my $obj = B::svref_2object( \$_ );
          last
            if ( $obj->FLAGS & B::SVf_POK )
            && !( $obj->FLAGS & ( B::SVf_IOK | B::SVf_NOK ) );
        }
        Carp::croak( "Unsupported default value" );
      }
      $param{optional} = 1;                 # any default implies optional
      $param{default} = $opts->{default}    # store default key
    }

    push @params, \%param;
  }

  # There must be at least one parameter
  Carp::croak "Signature must be positional" unless @params;

  # Validate parameter ordering and detect slurpy
  my $seen_optional = 0;
  my $has_slurpy    = 0;
  my $slurpy_index  = -1;

  for my $i ( 0 .. $#params ) {
    my $p = $params[$i];
    if ( $p->{slurpy} ) {
      # Slurpy must be last and must be unique
      Carp::croak "Parameter following slurpy parameter"
        if $has_slurpy || $i != $#params;

      Carp::croak "Slurpy parameter cannot be optional"
        if $p->{optional};

      $has_slurpy   = 1;
      $slurpy_index = $i;
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
  for my $i ( 0 .. $#fixed_params ) {
    my $type  = $fixed_params[$i]{isa};
    my $check = _generate_type_checker( $type );

    push @checks, sub {
      my ( $val ) = @_;
      return $check->( $val, "\$_[$i]" );
    };
  }

  # Compile checker for slurpy parameter (if present)
  my $slurpy_check;
  if ( $has_slurpy ) {
    my $type    = $params[$slurpy_index]{isa};
    my $generic = _generate_type_checker( $type );

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

    my @out;
 
    # Validate fixed (non-slurpy) positional arguments
    for my $i ( 0 .. $#fixed_params ) {
      my $p = $fixed_params[$i];
      my $val;

      # argument provided?
      if ( $i < $argc ) {
        $val = $_[$i];
      }

      # default provided?
      elsif ( exists $p->{default} ) {
        my $default = $p->{default};
        $val = ref( $default ) eq 'CODE' ? $default->() : $default;
      }
      
      # optional without default -> undef, no check
      elsif ( $p->{optional} ) {
        push @out, undef; 
        next;
      }
              
      $checks[$i]->( $val );
      push @out, $val;
    } #/ for my $i ( 0 .. $#fixed_params)

    # If there is no slurpy parameter, just return
    return @out unless $has_slurpy;

    # Slurpy: arrayref of remaining args (empty is allowed)
    my $rest = [];
    if ( $argc > @checks ) {
      $rest = [ @_[ @checks .. $argc - 1 ] ];
      $slurpy_check->( $rest );
    }

    # Return fixed values plus array ref for slurpy
    return ( @out, $rest );
  };

}

# ----------------------------------------------------------------------
# Internal helpers
# ----------------------------------------------------------------------
# signature(...)
#  1. _parse_signature_spec
#  2. _generate_type_checker  (per type)
#  3. _execute_signature      (per call)
#  4. _check_value            (generated subs)

#
# This subroutine generate a checker subroutine for a single type. 
# This function decides whether to use L<Type::API::Constraint::Inlined> 
# inline checking, L<Type::API::Constraint> checking, fallback L<Type::API> 
# style checking, or CODE-ref checking. 
#
#  - C<$type>: a type object or CODE reference
#
# It returns a sub that validates exactly one C<$value>, where C<$label> is a 
# string used in error messages (e.g. C<'$_[0]' or C<'$SLURPY'>).
#
#  Returns: a subroutine reference with signature ..
#           sub ($value, $label) -> $value or croak
#
sub _generate_type_checker {    # \&check ($type)
  my ( $type ) = @_;

  # Type::API::Constraint::Inlinable
  if ( Scalar::Util::blessed( $type )
    && $type->DOES( "Type::API::Constraint::Inlinable" )
    && $type->can_be_inlined
  ) {
    # Ask the type for inline code; it may use $val, $_[1], or local $_
    my $inline = $type->inline_check( '$val' );

    # Build the low-level predicate: ($type, $value) -> bool
    my $check  = eval "sub { my (\$type, \$val) = \@_; $inline; }"
      or die "Error compiling inline predicate: $@";

    # High-level checker: ($value, $label) -> $value or croak
    return sub {
      my ( $val, $label ) = @_;
      local $_ = $val;

      return $val if $type->$check( $val );
      Carp::croak( $type->get_message( $val ) . " (in $label)" );
    };
  }

  # Type::API::Constraint
  if ( Scalar::Util::blessed( $type )
    && $type->DOES( "Type::API::Constraint" )
  ) {
    return sub {
      my ( $val, $label ) = @_;
      local $_ = $val;

      return $val if $type->check( $val );
      Carp::croak( $type->get_message( $val ) . " (in $label)" );
    };
  } #/ if ( Scalar::Util::blessed...)

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
    $name = _coderef2text( $type )
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

#
# This subroutine reconstructs the code from Perl's internal syntax tree 
#
#  - C<$code>: a type constraint CODE reference
#
#  Returns: A string that maps the code reference from Perl's Optree.
#
sub _coderef2text {
  my ( $code ) = @_;
  state $DEPARSE = B::Deparse->new( "-P", "-sC" );
  my $body = $DEPARSE->coderef2text( $code );
  for ( $body ) {
    s/^\h+(?:use|no) (?:strict|warnings|feature|integer|utf8|bytes|re)\b[^\n]*\n//gm;
    s/^\h+package [^\n]*;\n//gm;
    s/\A\{\n\h+([^\n;]*);\n\}\z/{ $1 }/;
  }
  return $body;
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
