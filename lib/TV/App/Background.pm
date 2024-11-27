package TV::App::Background;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TBackground
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );

use TV::App::Const qw( cpBackground );
use TV::Objects::DrawBuffer;
use TV::Views::Const qw(
  gfGrowHiX
  gfGrowHiY
);
use TV::Views::Palette;
use TV::Views::View;

sub TBackground() { __PACKAGE__ }

use base TView;

# predeclare attributes
use fields qw(
  pattern
);

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'required' arguments
  assert ( $args{pattern} and !ref $args{pattern} );
  return $class->SUPER::BUILDARGS( %args );
}

sub BUILD {    # void (| \%args)
  my $self = shift;
  assert ( blessed $self );
  $self->{growMode} = gfGrowHiX | gfGrowHiY;
  return;
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
