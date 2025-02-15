=pod

=head1 NAME

TV::Menus::Menu - defines the class TMenu

=cut

package TV::Menus::Menu;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMenu
  new_TMenu
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
  weaken
);

use TV::toolkit;

sub TMenu() { __PACKAGE__ }
sub new_TMenu { __PACKAGE__->from(@_) }

# declare attributes
has items => ( is => 'rw' );
has deflt => ( is => 'bare' );

my $lock_value = sub {
  Internals::SvREADONLY( $_[0] => 1 )
    if exists &Internals::SvREADONLY;
};

my $unlock_value = sub {
  Internals::SvREADONLY( $_[0] => 0 )
    if exists &Internals::SvREADONLY;
};

sub BUILDARGS {    # \%args (|%args)
  my $class = shift;
  assert ( $class and !ref $class );
  my $args = STRICT ? check( {
    items   => { allow => sub { !defined $_[0] or blessed $_[0] } },
    default => { allow => sub { !defined $_[0] or blessed $_[0] } },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
  # 'init_arg' is not the same as the field name.
  $args->{deflt} = delete $args->{default};
  return $args;
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert( blessed $self );
  $self->{items} ||= undef;
  $self->{deflt} ||= $self->{items};
  weaken $self->{deflt} if $self->{deflt};
  $lock_value->( $self->{deflt} ) if STRICT;
  return;
}

sub from {    # $obj (| $itemList, | $TheDefault)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ >= 0 && @_ <= 2 );
  SWITCH: for ( scalar @_ ) {
    $_ == 0 and return $class->new();
    $_ == 1 and return $class->new( items => $_[0], default => $_[0] );
    $_ == 2 and return $class->new( items => $_[0], default => $_[1] );
  }
  return;
}

sub DEMOLISH {    # void ()
  my $self = shift;
  assert( blessed $self );
  while ( $self->{items} ) {
    my $temp = $self->{items};
    $self->{items} = $self->{items}{next};
    undef $temp;
  }
  $unlock_value->( $self->{deflt} ) if STRICT;
  return;
}

sub deflt {    # $view|undef (|$view|undef)
  my ( $self, $view ) = @_;
  assert ( blessed $self );
  assert ( !defined $view or blessed $view );
  if ( @_ == 2 ) {
    $unlock_value->( $self->{deflt} ) if STRICT;
    weaken $self->{deflt}
      if $self->{deflt} = $view;
    $lock_value->( $self->{deflt} ) if STRICT;
  }
  return $self->{deflt};
} #/ sub deflt

1
