package TV::Views::Palette;
# ABSTRACT: A class for managing color palettes in Turbo Vision 2.0.

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

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

sub from {    # $obj ($tp|$d, $len)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ >= 1 && @_ <= 2 );
  SWITCH: for ( scalar @_ ) {
    $_ == 1 and return $class->new( copy_from => $_[0] );
    $_ == 2 and return $class->new( data => $_[0], size => $_[1] );
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

__END__

=pod

=head1 NAME

TPalette - A class for managing color palettes in Turbo Vision 2.0.

=head1 SYNOPSIS

  use TV::Views;

  my $palette = TPalette->new( data => $data, size => length( $data ) );
  my $byte    = $palette->at( $index );

=head1 DESCRIPTION

In this Perl module the class I<TPalette> is created and the constructor I<new> 
and I<clone> as the methods I<assign> and I<at> are implemented to emulate 
the functionality of the Borland C++ code. 

=head1 METHODS

=head2 new

  my $obj = TPalette->new(%args);

Creates a new TPalette object.

=over

=item data

Stores the palette data. Used together with L</size>. (Str)

=item size

The size of the palette. Used together with L</data>. (Int)

=item copy_from

Copies data from another palette. Used instead of L</data> and L</size>. 
(TPalette)

=back

=head2 clone

  my $clone = TPalette->clone($self);

Creates a clone of the palette.

=head2 from

  my $obj = TPalette->from($tp | $d, $len);

Creates a TPalette object from another palette or data.

=head2 assign

  my $self = $self->assign($tp);

Assigns the data from another palette to the current palette.

=head2 at

  my $byte = $self->at($index);

Returns the color at the specified index. (Int)

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2025 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
