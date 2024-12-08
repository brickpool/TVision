=pod

=head1 NAME

TV::Menus::MenuItem - defines the class TMenuItem

=cut

package TV::Menus::MenuItem;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TMenuItem
  newLine
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Views::Const qw( hcNoContext );
use TV::Views::View;

sub TMenuItem() { __PACKAGE__ }

use parent 'UNIVERSAL::Object';

# declare attributes
use slots::less (
  next     => sub { },
  name     => sub { die 'required' },
  command  => sub { 0 },
  disabled => sub { !!0 },
  keyCode  => sub { die 'required' },
  helpCtx  => sub { hcNoContext },
  param    => sub { '' },
  subMenu  => sub { },
);

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'required' arguments
  assert ( defined $args{name} and !ref $args{name} );
  assert ( looks_like_number $args{keyCode} );
  # check 'isa'
  assert ( !defined $args{command} or looks_like_number $args{command} );
  assert ( !defined $args{subMenu} or blessed $args{subMenu} );
  assert ( !defined $args{helpCtx} or looks_like_number $args{helpCtx} );
  assert ( !ref $args{param} );
  assert ( !defined $args{next} or blessed $args{next} );
  return \%args;
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
  return $class->new( %args );
}

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

1
