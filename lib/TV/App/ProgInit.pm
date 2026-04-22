package TV::App::ProgInit;

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TProgInit
  new_TProgInit
);

use TV::toolkit;
use TV::toolkit::Types qw(
  CodeRef
  Object
);

sub TProgInit() { __PACKAGE__ }
sub new_TProgInit { __PACKAGE__->from(@_) }

# protected attributes
has createStatusLine => ( is => 'bare', default => sub { die 'required' } );
has createMenuBar    => ( is => 'bare', default => sub { die 'required' } );
has createDeskTop    => ( is => 'bare', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      createStatusLine => CodeRef, { alias => 'cStatusLine' },
      createMenuBar    => CodeRef, { alias => 'cMenuBar' },
      createDeskTop    => CodeRef, { alias => 'cDeskTop' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $obj ($cStatusLine, $cMenuBar, $cDeskTop)
  state $sig = signature(
    method => 1,
    pos    => [CodeRef, CodeRef, CodeRef],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( cStatusLine => $args[0], cMenuBar => $args[1], 
    cDeskTop => $args[2] );
}

sub createStatusLine {    # $statusLine ($r)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $r ) = $sig->( @_ );
  my ( $class, $code ) = ( ref $self, $self->{createStatusLine} );
  return $class->$code( $r );
}

sub createMenuBar {    # $menuBar ($r)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $r ) = $sig->( @_ );
  my ( $class, $code ) = ( ref $self, $self->{createMenuBar} );
  return $class->$code( $r );
}

sub createDeskTop {    # $deskTop ($r)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $r ) = $sig->( @_ );
  my ( $class, $code ) = ( ref $self, $self->{createDeskTop} );
  return $class->$code( $r );
}

1
