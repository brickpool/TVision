=pod

=head1 NAME

TV::Views::Palette - defines the class TPalette

=head1 DESCRIPTION

In this Perl module the class I<TPalette> is created and the constructor I<new> 
and I<clone> as the methods I<assign> and I<at> are implemented to emulate 
the functionality of the Borland C++ code. 

=cut

package TV::Views::Palette;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TPalette
  new_TPalette
);

require bytes;
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

sub TPalette() { __PACKAGE__ }
sub new_TPalette { __PACKAGE__->from(@_) }

sub new {    # $obj (%args)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  my $data = "\0";
  if ( $args{data} && $args{size} ) {
    my $d   = $args{data} . '';
    my $len = $args{size} || 0;
    $data = pack( 'C'.'a' x $len, $len, unpack( '(a)*', $d ) );
  }
  elsif ( $args{copy_from} ) {
    my $tp = $args{copy_from};
    $data = $$tp;
  }
  return bless \$data, $class;
} #/ sub new

sub from {    # $obj ($tp | $d, $len)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ >= 1 && @_ <= 2 );
  SWITCH: for ( scalar @_ ) {
    $_ == 0 and return $class->new( copy_from => $_[0] );
    $_ == 1 and return $class->new( data => $_[0], size => $_[1] );
  }
  return;
}

sub clone {    # $clone ($self)
  my $self = shift;
  assert ( blessed $self );
  my $data = $$self;
  return bless \$data, ref $self;
}

sub assign {    # $self ($tp)
  my ( $self, $tp ) = @_;
  assert ( blessed $self );
  assert ( ref $tp );
  $$self = $$tp;
  return $self;
}

sub at {    # $byte ($index)
  my ( $self, $index ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $index );
  return ord bytes::substr( $$self, $index, 1 );
}

use overload
  '@{}' => sub { [ unpack('C*', ${+shift}) ] },
  fallback => 1;

1
