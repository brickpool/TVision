package TV::Menus::MenuItem;
# ABSTRACT: Class linking text, hot key, command, and help for use within a menu

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
has name     => ( is => 'rw' );
has command  => ( is => 'rw' );
has disabled => ( is => 'rw' );
has keyCode  => ( is => 'rw' );
has helpCtx  => ( is => 'rw' );
has param    => ( is => 'rw' );
has subMenu  => ( is => 'rw' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  return check( {
    # set 'default' values, init_args => undef
    disabled => { default => !!0, no_override => 1 },
    # 'required' arguments
    name    => { required => 1, defined => 1, default => '', strict_type => 1 },
    keyCode => { required => 1, defined => 1, allow => qr/^\d+$/ },
    # check 'isa' (note: args can be undefined)
    command => { default => 0, allow => sub { $_[0] =~ /^\d+$/ } },
    subMenu => { allow => sub { !defined $_[0] or blessed $_[0] } },
    helpCtx => { default => hcNoContext, allow => sub { $_[0] =~ /^\d+$/ } },
    param   => { default => '', strict_type => 1 },
    next    => { allow => sub { !defined $_[0] or blessed $_[0] } },
  } => { @_ } ) || Carp::confess( last_error );
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert ( blessed $self );
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

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
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
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $aNext );
  $self->{next} = $aNext;
  return;
}

sub newLine () {    # $menuItem ()
  assert ( @_ == 0 );
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

__END__

=pod

=head1 NAME

TV::Menus::MenuItem - defines the class TMenuItem

=cut
