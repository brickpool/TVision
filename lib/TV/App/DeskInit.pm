package TV::App::DeskInit;

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TDeskInit
  new_TDeskInit
);

use PerlX::Assert::PP;
use TV::toolkit;
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  CodeRef
  Object
);

sub TDeskInit() { __PACKAGE__ }
sub new_TDeskInit { __PACKAGE__->from(@_) }

# protected attributes
has createBackground => ( is => 'bare', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      createBackground => CodeRef, { alias => 'cBackground' }
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return $args;
}

sub from {    # $obj ($cBackground)
  state $sig = signature(
    method => 1,
    pos    => [CodeRef],
  );
  my ( $class, $cBackground ) = $sig->( @_ );
  return $class->new( createBackground => $cBackground );
}

sub createBackground {    # $background ($r)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $r ) = $sig->( @_ );
  my ( $class, $code ) = ( ref $self, $self->{createBackground} );
  return $class->$code( $r );
}

1
