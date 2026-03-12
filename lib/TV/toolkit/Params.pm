package TV::toolkit::Params;
# ABSTRACT: Lightweight positional argument validation inspired by Type::Params

use 5.010;
use strict;
use warnings;

our $VERSION   = '0.06';
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

our @CARP_NOT = ( __PACKAGE__ );

# ----------------------------------------------------------------------
# Public API
# ----------------------------------------------------------------------

#
# Build-time constructor for a positional parameter validator.
#
# This function performs the following steps:
#
#   1. Parse the raw positional specification into a Signature object
#      via _build_signature_from_spec(). The Signature object contains
#      Parameter objects for all fixed parameters and optionally one
#      slurpy parameter.
#
#   2. Precompute all static metadata needed for efficient runtime
#      execution.
#
#   3. Pre-generate type-check closures for each fixed parameter using
#      _generate_type_checker(). These closures perform the actual
#      runtime validation of individual values.
#
#   4. Pre-generate the slurpy checker (if present), which validates
#      the arrayref of remaining arguments.
#
#   5. Delegate to _execute_signature(), which returns the final
#      runtime executor closure. The executor performs:
#         - arity validation
#         - default handling
#         - type checking
#         - slurpy collection
#
# The returned closure is the actual validator that will be invoked
# for each call site. All expensive work is done here at build time.
#
sub signature {
  my ( %args ) = @_;

  # Extract positional spec (pos or positional)
  my @spec = @{
      exists $args{pos}        ? $args{pos}
    : exists $args{positional} ? $args{positional}
    : Carp::croak "Signature must be positional"
  };

  # Handle optional method spec (Bool or Type)
  if ( exists $args{method} && $args{method} ) {
    my $method = ref $args{method} ? $args{method} : sub { 1 };
    unshift @spec, $method;
  }

  # Build Signature object from raw spec
  my $sig = _build_signature_from_spec( @spec );

  # Pre-compile type checkers for fixed parameters
  my $i = 0;
  foreach my $p ( @{ $sig->parameters } ) {
    my $type  = $p->type;
    my $check = _generate_type_checker( $type );
    my $idx = $i;

    $p->{coderef} = sub {
      my ( $val ) = @_;
      return $check->( $val, "\$_[$idx]" );
    };

    $i++;
  }

  # Pre-compile slurpy checker (if present)
  if ( $sig->has_slurpy ) {
    my $type = $sig->slurpy->type;
    my $check = _generate_type_checker( $type );

    $sig->slurpy->{coderef} = sub {
      my ( $val ) = @_;
      return $check->( $val, '$SLURPY' );
    };
  }

  # Delegate to executor builder
  return _execute_signature( $sig );
}

# ----------------------------------------------------------------------
# Internal staff
# ----------------------------------------------------------------------

#
# This subroutine parses a raw positional specification and constructs
# a Signature object. It receives:
#
#   - C<@spec> : alternating list of types and optional option-hashes
#
# The routine performs:
#   - creation of Parameter objects
#   - detection of the slurpy parameter (if any)
#   - enforcement of the optional-parameter block rule
#   - separation of fixed and slurpy parameters
#
# Returns: a Signature object representing the parsed specification
#
sub _build_signature_from_spec {    # \&signature_from_spec (@spec)
  my ( @spec ) = @_;

  my @params;
  my $slurpy_index;

  #
  # 1. Parse the raw spec into Parameter objects
  #
  my $i = 0;
  while ( @spec ) {
    my $isa  = shift @spec;
    my $opts = ( @spec && ref $spec[0] eq 'HASH' ) ? shift @spec : {};

    # Validate default value
    if ( exists $opts->{default} ) {
      my $default = $opts->{default};

      if ( !defined $default ) {
        # OK: undef
      }
      elsif ( !ref $default ) {
        # OK: simple scalar
      }
      elsif ( ref $default eq 'CODE' ) {
        # OK
      }
      elsif ( ref $default eq 'ARRAY' && @$default == 0 ) {
        # OK
      }
      elsif ( ref $default eq 'HASH' && !keys %$default ) {
        # OK
      }
      elsif ( ref $default eq 'SCALAR' && !ref $$default ) {
        # compile scalar-ref code
        my $src  = $$default;
        my $code = do {
          local $@;
          eval "sub { $src }"
            or Carp::croak "Invalid default expression '$src': $@";
        };
        $opts->{default} = $code;
      }
      else {
        Carp::croak "Default expected to be undef, string, coderef, or empty " .
          "arrayref/hashref";
      }
    }

    # Create Parameter object
    push @params, TV::Params::Parameter->new(
      isa      => $isa,
      optional => $opts->{optional} ? 1 : 0,
      ( exists $opts->{default} ? ( default => $opts->{default} ) : () ),
    );

    # Detect slurpy parameter
    $slurpy_index //= $i if $opts->{slurpy};

    $i++;
  } #/ while ( @spec )

  #
  # 2. Validate optional-block rules and slurpy rules
  #
  my $seen_optional = 0;
  my @fixed;
  my $slurpy_param;

  for my $i ( 0 .. $#params ) {
    my $p = $params[$i];

    # Handle slurpy parameter
    if ( defined $slurpy_index && $i == $slurpy_index ) {

      Carp::croak "Slurpy parameter cannot be optional"
        if $p->optional;

      Carp::croak "Parameter following slurpy parameter"
        if $i < $#params;

      $slurpy_param = $p;
      last;
    }

    # Optional-block rule:
    # Once an optional parameter appears, all following must be optional
    if ( $p->optional ) {
      $seen_optional = 1;
    }
    elsif ( $seen_optional ) {
      Carp::croak "Non-Optional parameter following Optional parameter";
    }

    push @fixed, $p;
  }

  #
  # 3. Build and return the Signature object
  #
  my $sig = TV::Params::Signature->new(
    parameters => \@fixed,
    ( defined $slurpy_param ? ( slurpy => $slurpy_param ) : () ),
  );

  return $sig;
}

#
# This subroutine generate a checker subroutine for a single type. 
# This function decides whether to use L<Type::API::Constraint::Inlined> 
# inline checking, L<Type::API::Constraint> checking, fallback L<Type::API> 
# style checking, or coderef checking. 
#
#  - C<$type>: a type object or CODE reference
#
# It returns a sub that validates exactly one C<$value>, where C<$label> is a 
# string used in error messages (e.g. C<'$_[0]' or C<'$SLURPY'>).
#
#  Returns: a code reference for on signature-entry -> sub ($value, $label)
#
sub _generate_type_checker {    # \&check ($type)
  my ( $type ) = @_;

  #
  # 1. Type::API::Constraint::Inlinable
  #
  if ( Scalar::Util::blessed( $type )
    && $type->DOES( "Type::API::Constraint::Inlinable" )
    && $type->can_be_inlined
  ) {
    # Ask the type for inline code; it may use $val, $_[1], or local $_
    my $inline = $type->inline_check( '$val' );

    # Build the low-level predicate: ($type, $value) -> bool
    my $check = do {
      local $@;
      eval "sub { my (\$type, \$val) = \@_; $inline; }"
        or Carp::croak "Error compiling inline predicate: $@";
    };

    # High-level checker: ($value, $label) -> $value or croak
    return sub {
      my ( $val, $label ) = @_;
      local $_ = $val;

      return $val if $type->$check( $val );
      Carp::croak( $type->get_message( $val ) . " (in $label)" );
    };
  }

  #
  # 2. Type::API::Constraint
  #
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

  # 
  # 3. Type::API-style object
  #
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

  #
  # 4. plain CODE ref
  #
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
# This subroutine constructs the runtime executor for a compiled signature.
# It receives the Signature object together with the pre-generated type
# checkers for fixed parameters and (optionally) the slurpy checker. It 
# receives:
#
#   - C<$signature> : a Signature-object with precompiled checker
#
# The returned closure performs:
#   - arity validation
#   - default materialization
#   - type checking for fixed parameters
#   - slurpy collection and validation (if present)
#
#  Returns: a code reference to validate the argument list -> sub (@args)
#
sub _execute_signature {    # \&executor ($signature)
  my ( $sig ) = @_;

  # Extract parameters from signature
  my @params = @{ $sig->parameters };

  # Precompute arity
  my $min_arity = scalar grep { !$_->optional } @params;
  my $max_arity = scalar @params;

  # Flags for optionals / slurpy
  my $has_optional = !! grep { $_->optional } @params;
  my $has_slurpy   = $sig->has_slurpy;

  # Get the pre-built checker for each signature entry
  my @checks = map { $_->coderef } @params;
  
  #
  # 1. Simple case, so keep it simple
  #
  if ( !$has_optional && !$has_slurpy ) {
    my $arity = $max_arity;

    return sub {
      # Adjust Carp stack level so errors point to the caller of the signature
      local $Carp::CarpLevel = 2;

      my $argc = @_;

      # Simple fixed-arity check
      if ( $argc != $arity ) {
        Carp::croak "Wrong number of parameters; got $argc; expected $arity";
      }

      # Increase level for checks so error locations look natural
      $Carp::CarpLevel += 2;

      # Validate all arguments in-place
      for my $i ( 0 .. $#checks ) {
        $checks[$i]->( $_[$i] );
      }

      # Hot path: return @_ unchanged
      return @_;
    };
  }

  # This block inspects a potential slurpy parameter and determines
  # whether it behaves like a HashRef by using its name, type and, as a last
  # resort, its coderef; it also captures the coderef for later use.
  my ( $slurpy_check, $slurpy_is_hash );
  if ( $has_slurpy ) {
    my $param = $sig->slurpy;
    my $type = $param->type;
    $slurpy_check = $param->coderef;
    if ( $param->has_name && $param->name =~ /^HashRef/ ) {
      $slurpy_is_hash = 1;
    }
    elsif ( Scalar::Util::blessed( $type ) && $type->can( 'check' ) ) {
      $slurpy_is_hash = $type->check( {} ) 
                    && !$type->check( [] );
    }
    else {
      local $@;
      $slurpy_is_hash = eval { $slurpy_check->( {} ) } 
                    && !eval { $slurpy_check->( [] ) };
    }
  }

  #
  # 2. Fallback, full support required
  #
  return sub {
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

    $Carp::CarpLevel += 2;

    my @out;

    # Validate fixed (non-slurpy) positional arguments
    for my $i ( 0 .. $#params ) {
      my $p = $params[$i];
      my $val;

      # argument provided?
      if ( $i < $argc ) {
        $val = $_[$i];
      }

      # default provided?
      elsif ( $p->has_default ) {
        my $d = $p->{default};
        $val = ref( $d ) eq 'CODE' ? $d->() : $d;
      }

      # optional without default -> stop, no further checks
      elsif ( $p->optional ) {
        last;
      }

      # Run type check
      $checks[$i]->( $val );
      push @out, $val;
    } #/ for my $i ( 0 .. $#fixed_params)

    # If there is no slurpy parameter, just return
    return @out unless $has_slurpy;

    # Slurpy: arrayref or hashref of remaining args (empty is allowed)
    my $rest       = [];
    my $rest_start = @checks;
    my $rest_count = $argc - $rest_start;

    if ( $rest_count > 0 ) {
      if ( $rest_count == 1 ) {
        my $last = $_[-1];
        if ( !$slurpy_is_hash ) {
          $rest = [$last];
        }
        elsif ( ref $last ne 'HASH' ) {
          $rest = {$last};
        }
        else {
          $rest = $last;
        }
      }
      else {
        my @slice = @_[ $rest_start .. $argc - 1 ];
        if ( $slurpy_is_hash ) {
          Carp::croak "Odd number of elements in slurpy hash parameter"
            if @slice % 2;
          $rest = {@slice};
        }
        else {
          $rest = \@slice;
        }
      }
      $slurpy_check->( $rest );
    }

    # Return fixed values plus array ref for slurpy
    return ( @out, $rest );
  };

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

# ----------------------------------------------------------------------
# Meta Objects
# ----------------------------------------------------------------------

#
# Represents a single positional parameter in a signature. Stores the
# associated type, optional/default metadata, and provides predicate
# methods used during validation. This object contains no runtime logic.
#
{
  package    # hide from CPAN
    TV::Params::Parameter;

  use strict;
  use warnings;

  sub new {
    my ( $class, %args ) = @_;

    my $self = bless {
      isa      => $args{isa},
      optional => $args{optional} ? 1 : 0,
    }, $class;

    my $name;
    if ( exists $args{name} ) {
      $name = $args{name};
    } 
    elsif ( Scalar::Util::blessed $args{isa} ) {
      my $type = $args{isa};
      $name = $type->name if $type->can( 'name' )
    } 
    $self->{name} = $name if defined $name && !ref $name && length $name;

    # a parameter with a default is always treated as optional
    if ( exists $args{default} ) {
      $self->{default}  = $args{default};
      $self->{optional} = 1;    # any default implies optional
    }

    return $self;
  }

  # accessors
  sub name     { $_[0]{name} } 
  sub type     { $_[0]{isa} }
  sub optional { $_[0]{optional} }
  sub default  { $_[0]{default} }
  sub coderef  { $_[0]{coderef} }

  # predicates
  sub has_name    { exists $_[0]{name} }
  sub has_default { exists $_[0]{default} }
}

#
# Represents a compiled positional signature consisting of fixed
# parameters and an optional slurpy parameter. Provides structural
# metadata used by the executor, but performs no validation itself.
#
{
  package    # hide from CPAN
    TV::Params::Signature;

  use strict;
  use warnings;

  sub new {
    my ( $class, %args ) = @_;

    my $self = bless {
      parameters => $args{parameters} || [],
    }, $class;

    if ( exists $args{slurpy} ) {
      $self->{slurpy} = $args{slurpy};
    }

    return $self;
  }

  # accessors
  sub parameters { $_[0]{parameters} }
  sub slurpy     { $_[0]{slurpy} }

  # predicates
  sub has_parameters { @{ $_[0]{parameters} } > 0 }
  sub has_slurpy     { exists $_[0]{slurpy} }
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

  # Example with simple scalar defaults
  sub compute_values {
    state $sig = signature(
      pos => [
        Int,                          # required
        Int, { default => 10 },       # default integer value
        Int, { default => "999" },    # default string
      ],
    );

    my ( $a, $b, $c ) = $sig->( @_ );
    return $a + $b + $c;
  }

  # Example with CODE/SCALAR-ref defaults
  sub compute_magic {
    state $sig = signature(
      pos => [
        Int,
        Int, { default => sub { 2 * 21 } },    # compiled into 42
        Int, { default => \'6 * 111' },        # smarter into 666
      ],
    );

    my ( $x, $y, $z ) = $sig->( @_ );
    return $x + $y + $z;
  }
            
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

Default handling for optional parameters.

=item *

Helpful error messages including argument index or C<"$SLURPY">.

=back

All type checking logic is compiled once at signature creation time,
resulting in faster validation than doing checks inside the subroutine body.

=head2 optional parameters

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

=head2 default values

Parameters may define a default value using C<< default => ... >> inside the
option hashref:

  positional => [
    Int,
    Int, { default => 42 },          # simple scalar
    Int, { default => \"333 * 2" },  # string ref
  ];

Any parameter with a default is automatically optional.

Supported forms of default values are:

=over 4

=item * C<undef>

=item * Plain non-reference scalars (strings or numbers)

=item * Empty arrayrefs (C<[]>)

=item * Empty hashrefs (C<{}>)

=item * CODE references, which are executed to generate the default value

=item * SCALAR references containing a string of Perl source code

=back

Unsupported defaults will cause an exception at signature construction time.

Default values are validated against the parameter type, just like explicit
arguments.

=head2 slurpy parameters

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

A slurpy parameter must have a type constraint that accepts the value
produced by slurpy processing. In array-slurpy mode this value is an
array reference; in hash-slurpy mode it is a hash reference.

=item *

Slurpy processing produces either an array reference or a hash reference,
depending on the slurpy mode. This value is then validated against the
type constraint of the slurpy parameter.

=item B<Array‑slurpy>

Remaining arguments are collected into an array reference:

=over 4

=item * Zero remaining arguments: []

=item * One remaining argument: [ $value ]

=item * Multiple remaining arguments: [ @values ]

=back

=item B<Hash‑slurpy>

Remaining arguments are collected into a hash reference:

=over 4

=item * Zero remaining arguments: {}

=item * One remaining argument: ( ref $value eq 'HASH' ) ? $value : { $value }

=item * Multiple remaining arguments: { @values }

=back

=item *

Simple types such as C<Any> or C<Ref> accept these structures and are
therefore valid slurpy parameter types, resulting in an array reference.

=back

=head2 method signatures

The C<method> option provides syntactic sugar for defining method invocants
in a positional signature. It prepends an additional, non-optional positional
parameter to the beginning of the signature.

This parameter is treated exactly like any other entry in C<pos>, and supports
the same type specifications (Type::Tiny, Type::API, CODE predicates, etc.).

=head3 method => 1

Using C<< method => 1 >> prepends a dummy predicate that always returns true.
This means:

=over 4

=item *

An invocant is required (arity increases by one).

=item *

The invocant is not type-checked.

=item *

The implementation simply uses a C<sub { 1 }> predicate.

=back

Example:

  signature(
    method => 1,
    pos    => [ Int, Str ],
  );

behaves exactly like:

  signature(
    pos => [ sub { 1 }, Int, Str ],
  );

=head3 method => $type

If the argument is a type object or predicate, it is prepended as-is to the
positional parameter list. This allows expressing object or class method
signatures declaratively.

Examples:

  signature(
    method => Object,
    pos    => [ Int ],
  );

is equivalent to:

  signature(
    pos => [ Object, Int ],
  );

If neither C<pos> nor C<positional> is provided, an empty positional list is
created automatically, and the method parameter is prepended. This allows
signatures consisting solely of an invocant.

=head1 LIMITATIONS

This module implements only a subset of Type::Params. Notable limits:

=over 4

=item * Only positional parameters are supported.

No named parameters. Only C<pos> or C<position> are valid specifications.

=item * No coercions or automatic type conversions.

=item * No advanced parameter kinds.

No parameter aliases, unions, parameter packs, or complex tuple types.

The L<Type::Standard> objects C<Slurpy['a]> and C<Optional['a]> are not 
recognized and therefore do not replace the parameters 
C<< optional => 1 >> or C<< slurpy => 1 >>.

=item * Having any optionals disables the fast-path.

Note that having any parameter with a optional or default disables the 
fast-path optimization in which the validator can return C<@_> unchanged.

=item * No global caching.

Each subroutine must store its own C<state> variable.

=item * Only basic support for method specification

C<method> is purely syntactic sugar. It simply prepends an additional 
positional parameter to the beginning of the signature. It introduces no
special method semantics.

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

=item * L<Type::API>

=item * L<Type::Params>

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
