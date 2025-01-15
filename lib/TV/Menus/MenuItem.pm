=pod

=head1 NAME

TV::Menus::MenuItem - defines the class TMenuItem

=cut

package TV::Menus::MenuItem;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMenuItem
  newLine
  new_TMenuItem
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Views::Const qw( hcNoContext );
use TV::Views::View;
use TV::toolkit;

sub TMenuItem() { __PACKAGE__ }
sub new_TMenuItem { __PACKAGE__->from(@_) }

# declare attributes
has next     => ( is => 'rw' );
has name     => ( is => 'rw', default => sub { die 'required' } );
has command  => ( is => 'rw', default => sub { 0 } );
has disabled => ( is => 'rw', default => sub { !!0 } );
has keyCode  => ( is => 'rw', default => sub { die 'required' } );
has helpCtx  => ( is => 'rw', default => sub { hcNoContext } );
has param    => ( is => 'rw', default => sub { '' } );
has subMenu  => ( is => 'rw' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  return STRICT ? check( {
    # 'required' arguments
    name    => { required => 1, defined => 1, allow => sub { !ref $_[0] } },
    keyCode => { required => 1, defined => 1, allow => qr/^\d+$/ },
    # check 'isa' (note: args can be undefined)
    command => {
      default => 0,
      defined => 1,
      allow   => sub { looks_like_number $_[0] }
    },
    subMenu => { allow => sub { !defined $_[0] or blessed $_[0] } },
    helpCtx => {
      default => hcNoContext,
      defined => 1,
      allow   => sub { looks_like_number $_[0] }
    },
    param => { allow => sub { !defined $_[0] or !ref $_[0] } },
    next  => { allow => sub { !defined $_[0] or blessed $_[0] } },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
}

sub BUILD {    # void (| \%args)
  my $self = shift;
  assert( blessed $self );
  $self->{disabled} = !TView->commandEnabled( $self->{command} );
  return;
}

sub from {    # $obj ($name, | $command, $keyCode, | $subMenu, $helpCtx, | $param, $next)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ >= 3 && @_ <= 6 );
  my %args = ();
  my @params = looks_like_number( $_[2] )
             ? qw(name command keyCode helpCtx param next)
             : qw(name keyCode subMenu helpCtx next);
  @args{@params} = @_;
  $args{helpCtx} ||= 0;
  return $class->new( %args );
}

sub DEMOLISH {    # void ()
  my $self = shift;
  assert ( blessed $self );
  undef $self->{name};
  if ( $self->{command} == 0 ) {
    undef $self->{subMenu};
  }
  else {
    undef $self->{param};
  }
  return;
} #/ sub DEMOLISH

sub append {    # void ($aNext)
  my ( $self, $aNext ) = @_;
  assert ( blessed $self );
  assert ( blessed $aNext );
  $self->{next} = $aNext;
  return;
}

sub newLine {    # $menuItem ()
  assert( @_ == 0 );
  return TMenuItem->new(
    name    => '',
    command => 0,
    keyCode => 0,
    helpCtx => hcNoContext,
    param   => '',
    next    => undef,
  );
} #/ sub newLine

1
