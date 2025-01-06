=pod

=head1 NAME

TV::Menus::StatusItem - defines the class TStatusItem

=cut

package TV::Menus::StatusItem;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TStatusItem
  new_TStatusItem
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::toolkit;

sub TStatusItem() { __PACKAGE__ }
sub new_TStatusItem { __PACKAGE__->from(@_) }

# declare attributes
slots next    => ();
slots text    => ( default => sub { '' } );
slots keyCode => ( default => sub { 0 } );
slots command => ( default => sub { 0 } );

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'required' arguments
  assert ( defined $args{text} and !ref $args{text} );
  assert ( looks_like_number $args{keyCode} );
  assert ( looks_like_number $args{command} );
  # 'isa' is undef or TStatusItem
  assert ( !defined $args{next} or blessed $args{next} );
  return \%args;
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
