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

BEGIN {
  require TV::Objects::Object;
  *mk_constructor = \&TV::Objects::Object::mk_constructor;
  *mk_accessors   = \&TV::Objects::Object::mk_accessors;
}

sub TMenuItem() { __PACKAGE__ }

# predeclare attributes
use fields qw(
  next
  name
  command
  disabled
  keyCode
  helpCtx
  param
  subMenu
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
  # set default values if not defined
  $self->{command} ||= 0;
  $self->{disabled} = !TView->commandEnabled( $self->{command} );
  $self->{helpCtx} ||= hcNoContext;
  $self->{param}   ||= '';
  $self->{next}    ||= undef;
  $self->{subMenu} ||= undef;
  return;
}

sub init {    # $obj ($name, | $command, $keyCode, | $subMenu, $helpCtx, | $param, $next)
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

__PACKAGE__
  ->mk_constructor
  ->mk_accessors;

1
