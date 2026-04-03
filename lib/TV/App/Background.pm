package TV::App::Background;
# ABSTRACT: TBackground forms the background for the Turbo Vision applications.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TBackground
  new_TBackground
);

use PerlX::Assert::PP;
use TV::toolkit;
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  :Object
  Str
);

use TV::App::Const qw( cpBackground );
use TV::Views::Const qw( :gfXXXX );
use TV::Views::DrawBuffer;
use TV::Views::Palette;
use TV::Views::View;

sub TBackground() { __PACKAGE__ }
sub new_TBackground { __PACKAGE__->from(@_) }

extends TView;

# protected attributes
has pattern => ( is => 'ro', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds  => Object,
      pattern => Str, { alias => 'aPattern' }
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return $args;
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{growMode} = gfGrowHiX | gfGrowHiY;
  return;
}

sub from {    # $obj ($bounds, $aPattern)
  state $sig = signature(
    method => 1,
    pos    => [Object, Str],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], pattern => $args[1] );
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $b = TDrawBuffer->new();

  $b->moveChar( 0, $self->{pattern}, $self->getColor(0x01), $self->{size}{x} );
  $self->writeLine( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpBackground, 
    size => length( cpBackground )
  );
  return $palette->clone();
}

1

__END__

=pod

=head1 NAME

TV::App::Background - forms the background for the Turbo Vision applications.

=head1 DESCRIPTION

TBackground contains the background pattern that forms the backdrop of most 
Turbo Vision applications.

=head1 ATTRIBUTES

=over

=item pattern

The bit pattern that is replicated to form the background design.

=back

=head1 METHODS

=head2 new

  my $background = TBackground->new(bounds => $bounds, pattern => $pattern);

Use TBackground->new to create a new background object with specified size and 
pattern.

=head2 draw

  $self->draw();

Draws the background pattern on the screen.

=head2 from

  my $background = TBackground->from($bounds, $aPattern);

Creates a TBackground object with specified bounds and pattern.

=head2 getPalette

  my $palette = $self->getPalette();

Retrieves the color palette for the background.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
