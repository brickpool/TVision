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
use Hash::Util;
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Views::Const qw( hcNoContext );
use TV::Views::View;

sub TMenuItem() { __PACKAGE__ }

our %FIELDS = (
  next     => 1,
  name     => 2,
  command  => 3,
  disabled => 4,
  keyCode  => 5,
  helpCtx  => 6,
  param    => 7,
  subMenu  => 7,  # yes, param and subMenu are equal
);

my $new = sub {    # $obj ($aName, $aCommand, $aKeyCode, | $aHelpCtx, | $p, | $aNext)
  my ( $class, $aName, $aCommand, $aKeyCode, $aHelpCtx, $p, $aNext ) = @_;
  assert ( $class and !ref $class );
  assert ( defined $aName and !ref $aName );
  assert ( looks_like_number $aCommand );
  assert ( looks_like_number $aKeyCode );
  assert ( !defined $aHelpCtx or looks_like_number $aHelpCtx );
  assert ( !ref $p );
  assert ( !defined $aNext or blessed $aNext );
  $aHelpCtx ||= hcNoContext;
  $p        ||= '';
  $aNext    ||= undef;
  my $self = {
    name     => ''. $aName,
    command  => 0+ $aCommand,
    disabled => !TView->commandEnabled( 0+ $aCommand ),
    keyCode  => 0+ $aKeyCode,
    helpCtx  => 0+ $aHelpCtx,
    param    => ''. $p,
    next     => $aNext,
  };
  bless $self, $class;
  Hash::Util::lock_keys_plus( %$self, qw( subMenu ) ) if STRICT;
  return $self;
};

my $new_submenu = sub {    # $obj ($aName, $aKeyCode, $aSubMenu|undef, | $aHelpCtx, | $aNext)
  my ( $class, $aName, $aKeyCode, $aSubMenu, $aHelpCtx, $aNext ) = @_;
  assert ( $class and !ref $class );
  assert ( defined $aName and !ref $aName );
  assert ( looks_like_number $aKeyCode );
  assert ( !defined $aSubMenu or blessed $aSubMenu );
  assert ( !defined $aHelpCtx or looks_like_number $aHelpCtx );
  assert ( !defined $aNext or blessed $aNext );
  $aHelpCtx ||= hcNoContext;
  $aNext    ||= undef;
  my $self = {
    name     => ''. $aName,
    command  => 0,
    disabled => !TView->commandEnabled( 0 ),
    keyCode  => 0+ $aKeyCode,
    helpCtx  => 0+ $aHelpCtx,
    subMenu  => $aSubMenu,
    next     => $aNext,
  };
  bless $self, $class;
  Hash::Util::lock_keys_plus( %$self, qw( param ) ) if STRICT;
  return $self;
};

sub new {    # $obj (@)
  !defined $_[3] || ref $_[3]
    ? goto $new_submenu
    : goto $new;
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

sub DESTROY {    # void ()
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
} #/ sub DESTROY

my $_mk_accessors = sub {
  my $pkg = shift;
  for my $field ( keys %FIELDS ) {
    no strict 'refs';
    my $fullname = "${pkg}::$field";
    *$fullname = sub {
      assert( blessed $_[0] );
      $_[0]->{$field} = $_[1] if @_ > 1;
      $_[0]->{$field};
    };
  }
}; #/ $_mk_accessors = sub

__PACKAGE__->$_mk_accessors();

1
