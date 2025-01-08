=pod

=head1 NAME

TV::Menus::StatusItem - defines the class TStatusItem

=cut

package TV::Menus::StatusItem;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStatusItem
  new_TStatusItem
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

use TV::toolkit;

sub TStatusItem() { __PACKAGE__ }
sub new_TStatusItem { __PACKAGE__->from(@_) }

# declare attributes
has next    => ( is => 'rw' );
has text    => ( is => 'rw', default => sub { '' } );
has keyCode => ( is => 'rw', default => sub { 0 } );
has command => ( is => 'rw', default => sub { 0 } );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  return STRICT ? check( {
    # 'required' arguments
    text    => { required => 1, defined => 1, allow => sub { !ref shift } },
    keyCode => { required => 1, defined => 1, allow => qr/^\d+$/ },
    command => { required => 1, defined => 1, allow => qr/^\d+$/ },
    # check 'isa' (note: 'next' can be undefined)
    next    => { allow => sub { !defined $_[0] or blessed $_[0] } },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
}

sub from {    # $obj ($aText, $key, $cmd, | $aNext)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ >= 3 && @_ <= 4 );
  return $class->new( 
    text => $_[0], keyCode => $_[1], command => $_[2], next => $_[3]
  );
}

sub DEMOLISH {    # void ()
  my $self = shift;
  assert( blessed $self );
  undef $self->{text};
  return;
}

1
