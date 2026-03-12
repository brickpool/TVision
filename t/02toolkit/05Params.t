use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  if ( eval { require TV::toolkit::Types } ) {
    note 'use TV::toolkit::Types';
    use_ok 'TV::toolkit::Types', qw( Num Str Int ArrayRef );
  }
  elsif ( eval { require Types::Standard } ) {
    note 'use Types::Standard';
    use_ok 'Types::Standard', qw( Num Str Int ArrayRef );
  } 
  else {
    plan skip_all => 'Test irrelevant without a Type constraint library';
  }
  use_ok 'TV::toolkit::Params', qw( signature );
}

# Helper for slurpy tests
sub slurpy_sig {
  return signature(
    pos => [
      Num,
      ArrayRef[Num], { slurpy => 1 },
    ],
  );
}

subtest 'Test specification options' => sub {
  throws_ok { signature( bad => [ foo => Num, bar => Int ] ) }
    qr/Signature must be positional/,
      'detect non positional option';

  lives_ok { 
    my $sig = signature( method => 1, pos => [] );
    $sig->( 'Any' )
  } 'method option is supported';
};

subtest 'Mandatory-only parameters' => sub {
  my $sig = signature(
    pos => [ Num, Int ],
  );

  lives_ok { my ( $a, $b ) = $sig->( 3, 2 ) } 'mandatory args ok';
  throws_ok { $sig->( 3 ) }
    qr/Wrong number of parameters; got 1; expected 2/,
      'too few mandatory args';
  throws_ok { $sig->( 3, 2, 1 ) }
    qr/Wrong number of parameters; got 3; expected 2/,
      'too many mandatory args';
};

subtest 'Optional parameters (must form trailing block)' => sub {
  my $sig = signature(
    pos => [
      Num,
      Str, { optional => 1 },
      Str, { optional => 1 },
    ],
  );

  lives_ok { my ( $a, $b, $c ) = $sig->( 5 ) } 'only mandatory ok';
  lives_ok { my ( $a, $b, $c ) = $sig->( 5, "x" ) } 'one optional ok';
  lives_ok { my ( $a, $b, $c ) = $sig->( 5, "x", "y" ) } 'two optional ok';

  throws_ok { $sig->() }
    qr/Wrong number of parameters; got 0; expected 1/,
      'too few optional-block args';

  throws_ok { $sig->( 5, "x", "y", "z" ) }
    qr/Wrong number of parameters; got 4; expected 1 to 3/,
      'too many optional-block args';
};

subtest 'Check wrong ordering: non-optional after optional' => sub {
  throws_ok {
    signature(
      pos => [
        Num,
        Str, { optional => 1 },
        Num,    # invalid: mandatory after optional
      ],
    );
  } 
  qr/Non-Optional parameter following Optional parameter/,
    'non-optional after optional detected';
};

subtest 'Slurpy must be last' => sub {
  throws_ok {
    signature(
      pos => [
        Num,
        ArrayRef[Num], { slurpy => 1 },
        Int,    # invalid: parameter after slurpy
      ],
    );
  }
  qr/Parameter following slurpy parameter/,
    'slurpy must be last';
};

subtest 'Slurpy usage and return semantics' => sub {
  my $sig = slurpy_sig();

  lives_ok {
    my ( $a, $rest ) = $sig->( 1, 2, 3, 4 );
    is( $a, 1, 'first arg ok' );
    is_deeply( $rest, [ 2, 3, 4 ], 'slurpy rest arrayref ok' );
  } 'slurpy multi rest ok';

  lives_ok {
    my ( $a, $rest ) = $sig->( 9 );
    is_deeply( $rest, [], 'slurpy empty rest ok' );
  } 'slurpy empty rest ok (min_arity satisfied)';
};

subtest 'Slurpy type errors' => sub {
  my $sig = slurpy_sig();

  throws_ok { $sig->( 1, "x" ) }
    qr/did not pass type constraint.*Slurpy/i,
      'slurpy type error: non-num inside ArrayRef[Num]';
};

subtest 'Optional + Slurpy combined' => sub {
  my $sig = signature(
    pos => [
      Num,    # mandatory
      Str,           { optional => 1 },
      ArrayRef[Num], { slurpy   => 1 },
    ],
  );

  lives_ok {
    my ( $a, $b, $rest ) = $sig->( 5, "x", 1, 2, 3 );
    is( $a, 5,   'fixed arg 1 ok' );
    is( $b, "x", 'optional arg ok' );
    is_deeply( $rest, [ 1, 2, 3 ], 'slurpy rest ok' );
  } 'optional + slurpy ok';

  throws_ok { $sig->() }
    qr/Wrong number of parameters; got 0; expected at least 1/,
      'optional+slurpy: too few args';
};

subtest 'Default-scalar' => sub {
  my $sig = signature(
    pos => [
      Num,
      Str, { default => "X" },
    ],
  );

  lives_ok {
    my @out = $sig->( 42 );
    is_deeply \@out, [ 42, "X" ], "default scalar applied";
  } 'default scalar ok';
};

subtest 'Default-CODE (Lazy)' => sub {
  my $sig = signature(
    pos => [
      Num,
      Str, { default => sub { "GEN" } },
    ],
  );

  lives_ok {
    my @out = $sig->( 10 );
    is_deeply \@out, [ 10, "GEN" ], "default CODE applied";
  } 'default coderef ok';
};

subtest 'Default-String ref' => sub {
  my $sig = signature(
    pos => [
      Num,
      Str, { default => \"333 * 2" },
    ],
  );

  lives_ok {
    my @out = $sig->( 42 );
    is_deeply \@out, [ 42, 666 ], "default scalar applied";
  } 'default scalar ok';
};

subtest 'Default = undef' => sub {
  my $sig = signature(
    pos => [
      Num,
      Str, { default => undef },
    ],
  );

  throws_ok { $sig->( 7 ) }
    qr/Undef did not pass type constraint "Str"/,
      'default is undef';
};

subtest 'Default-Array ref' => sub {
  my $sig = signature(
    pos => [
      Num,
      ArrayRef, { default => [] },
    ],
  );

  lives_ok {
    my @out = $sig->( 42 );
    is_deeply \@out, [ 42, [] ], "default array ref applied";
  } 'default array ref ok';
};

done_testing();
