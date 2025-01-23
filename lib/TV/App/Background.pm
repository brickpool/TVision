package TV::App::Background;
# ABSTRACT: TBackground forms the background for the Turbo Vision applications.

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

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw( blessed );

use TV::App::Const qw( cpBackground );
use TV::Views::Const qw( :gfXXXX );
use TV::Views::DrawBuffer;
use TV::Views::Palette;
use TV::Views::View;

use TV::toolkit;

sub TBackground() { __PACKAGE__ }
sub new_TBackground { __PACKAGE__->from(@_) }

extends TView;

# declare attributes
has pattern => ( is => 'rw', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  return STRICT ? check( {
    bounds  => { required => 1, defined => 1, allow => sub { blessed shift } },
    pattern => { required => 1, defined => 1, allow => sub { !ref shift } },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
} #/ sub BUILDARGS

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert ( blessed $self );
  $self->{growMode} = gfGrowHiX | gfGrowHiY;
  return;
}

sub from {    # $obj ($bounds, $aPattern)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 2 );
  return $class->new(
    bounds  => $_[0], 
    pattern => $_[1],
  );
}

sub draw {    # void ()
  my $self = shift;
  assert ( blessed $self );
  my $b = TDrawBuffer->new();

  $b->moveChar( 0, $self->{pattern}, $self->getColor(0x01), $self->{size}{x} );
  $self->writeLine( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  return;
}

my $palette;
sub getPalette {    # $palette ()
  my $self = shift;
  assert ( blessed $self );
  $palette ||= TPalette->new(
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

Copyright (c) 2021-2025 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
