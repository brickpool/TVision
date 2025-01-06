=pod

=head1 NAME

TV::Menus::Menu - defines the class TMenu

=cut

package TV::Menus::Menu;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TMenu
  new_TMenu
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::toolkit;

sub TMenu() { __PACKAGE__ }
sub new_TMenu { __PACKAGE__->from(@_) }

# declare attributes
slots items => ();
slots deflt => ();

sub BUILDARGS {    # \%args (%args)
  my ( $class, %args ) = @_;
  # 'init_arg' is not the same as the field name.
  $args{deflt} = delete $args{default};
  # 'isa' is undef or TMenuItem
  assert ( !defined $args{items} or blessed $args{items} );
  assert ( !defined $args{deflt} or blessed $args{deflt} );
  return \%args;
}

sub BUILD {    # void (| \%args)
  my $self = shift;
  assert( blessed $self );
  $self->{items} ||= undef;
  $self->{deflt} ||= $self->{items};
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
    $self->{items} = $self->{items}->{next};
    undef $temp;
  }
}

1
