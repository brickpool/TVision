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

sub BUILDARGS {    # \%args (@|%)
  my $class = shift;
  assert ( $class and !ref $class );

  # predefining %args
  my %args = @_ % 2 ? () : @_;

  # Check %args, and copy @_ to %args if 'name' and 'keyCode' are not present
  my @params = qw( name keyCode );
  my $notall = grep( exists $args{$_} => @params ) != @params;
  if ( $notall ) {
    %args = ();
    @params = looks_like_number( $_[2] )
            ? qw(name command keyCode helpCtx param next)
            : qw(name keyCode subMenu helpCtx next);
    @args{@params} = @_;
  }

  # set default values if not defined
  $args{command} ||= 0;
  $args{helpCtx} ||= hcNoContext;
  $args{param}   ||= '';
  
  # check 'isa' (note: 'next' and 'subMenu' can be undefined)
  assert ( !defined $args{next} or blessed $args{next} );
  assert ( defined $args{name} and !ref $args{name} );
  assert ( looks_like_number $args{command} );
  assert ( looks_like_number $args{keyCode} );
  assert ( looks_like_number $args{helpCtx} );
  assert ( defined $args{param} and !ref $args{param} );
  assert ( !defined $args{subMenu} or blessed $args{subMenu} );

  return \%args;
}

sub BUILD {    # void (| \%args)
  my $self = shift;
  assert( blessed $self );
  $self->{disabled} = !TView->commandEnabled( $self->{command} );
  return;
}

sub append {    # void ($aNext)
  my ( $self, $aNext ) = @_;
  assert ( blessed $self );
  assert ( blessed $aNext );
  $self->{next} = $aNext;
  return;
}

sub newLine {    # $menuItem ()
  assert ( @_ == 0 );
  return TMenuItem->new( '', 0, 0, hcNoContext, '', undef );
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

__PACKAGE__
  ->mk_constructor
  ->mk_accessors;

1
