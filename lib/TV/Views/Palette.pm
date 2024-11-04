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
);

require bytes;

sub TPalette() { __PACKAGE__ }

sub new {    # $obj (%args)
  my ( $class, %args ) = @_;
  my $data = "\0";
  if ( $args{data} && $args{size} ) {
    my $d   = $args{data} . '';
    my $len = $args{size} || 0;
    $data = pack( 'C'.'a' x $len, $len, unpack( '(a1)*', $d ) );
  }
  elsif ( $args{copy_from} ) {
    my $tp = $args{copy_from};
    $data = $$tp;
  }
  return bless \$data, $class;
} #/ sub new

sub clone {    # $clone ($self)
  my ( $self ) = @_;
  my $data = $$self;
  return bless \$data, ref $self;
}

sub assign {    # $self ($tp)
  my ( $self, $tp ) = @_;
  $$self = $$tp;
  return $self;
}

sub at {    # $byte ($indef)
  my ( $self, $index ) = @_;
  return ord bytes::substr( $$self, $index, 1 );
}

use overload
  '@{}' => sub { [ unpack('C*', ${+shift}) ] },
  fallback => 1;

1
