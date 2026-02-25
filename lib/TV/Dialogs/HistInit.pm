package TV::Dialogs::HistInit;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THistInit
  new_THistInit
);

use Carp ();
use PerlX::Assert::PP;
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Views::Const qw(
  sbHandleKeyboard
  sbHorizontal
  sbVertical
);
use TV::toolkit;

sub THistInit() { __PACKAGE__ }
sub new_THistInit { __PACKAGE__->from(@_) }

# declare attributes
has createListViewer => ( is => 'bare' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert { $class and !ref $class };
  local $Params::Check::PRESERVE_CASE = 1;
  my $args = check( {
    cListViewer => {
      required    => 1, 
      defined     => 1, 
      default     => sub { }, 
      strict_type => 1,
    },
  } => { @_ } ) || Carp::confess( last_error );
  # 'init_arg' is not equal to the field name
  $args->{createListViewer} = delete $args->{cListViewer};
  return $args;
} #/ sub BUILDARGS

sub from {    # $obj ($cListViewer)
  my $class = shift;
  assert { $class and !ref $class };
  assert { @_ == 1 };
  return $class->new( cListViewer => $_[0] );
}

sub createListViewer {    # $listViewer ($r, $win, $historyId)
  my ( $self, $r, $win, $historyId ) = @_;
  assert { @_ == 4 };
  assert { blessed $self };
  assert { ref $r };
  assert { blessed $win };
  assert { looks_like_number $historyId };
  my ( $class, $code ) = ( ref $self, $self->{createListViewer} );
  return $class->$code( $r, $win, $historyId );
}

1
