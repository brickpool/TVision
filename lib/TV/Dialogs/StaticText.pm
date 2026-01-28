package TV::Dialogs::StaticText;
# ABSTRACT: Displays fixed text inside a Turbo Vision dialog

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStaticText
  new_TStaticText
);

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  readonly
);

use TV::Dialogs::Const qw( cpStaticText );
use TV::Views::Const qw( gfFixed );
use TV::Views::DrawBuffer;
use TV::Views::Palette;
use TV::Views::View;
use TV::toolkit;

sub TStaticText() { __PACKAGE__ }
sub name() { 'TStaticText' }
sub new_TStaticText { __PACKAGE__->from(@_) }

extends TView;

# declare attributes
has text => ( is => 'ro' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_ );
  my $args2 = check( {
    text => { required => 1, defined => 1, default => '', strict_type => 1 },
  } => { @_ } ) || Carp::confess( last_error );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert ( blessed $self );
  $self->{growMode} |= gfFixed;
  return;
}

sub from {    # $obj ($bounds, $aText)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 2 );
  return $class->new( bounds => $_[0], text => $_[1] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  $self->{text} = undef;
  return;
}

sub draw {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );

  my $color;
  my $center;
  my ( $i, $j, $l, $p, $y );
  my $b = TDrawBuffer->new();
  my $s;

  $color = $self->getColor( 1 );
  $self->getText( $s );
  $l      = length( $s );
  $p      = 0;
  $y      = 0;
  $center = !!0;
  while ( $y < $self->{size}{y} ) {
    $b->moveChar( 0, ' ', $color, $self->{size}{x} );
    if ( $p < $l ) {
      if ( substr( $s, $p, 1 ) eq "\003" ) {
        $center = 1;
        ++$p;
      }
      $i = $p;
      do {
        $j = $p;
        while ( $p < $l && substr( $s, $p, 1 ) eq ' ' ) {
          ++$p;
        }
        while ( $p < $l
          && substr( $s, $p, 1 ) ne ' '
          && substr( $s, $p, 1 ) ne "\n" )
        {
          ++$p;
        }
        } while ( $p < $l
          && $p < $i + $self->{size}{x} 
          && substr( $s, $p, 1 ) ne "\n"
        );
      if ( $p > $i + $self->{size}{x} ) {
        if ( $j > $i ) {
          $p = $j;
        }
        else {
          $p = $i + $self->{size}{x};
        }
      }
      if ( $center ) {
        $j = int( ( $self->{size}{x} - $p + $i ) / 2 );
      }
      else {
        $j = 0;
      }
      $b->moveStr( $j, substr( $s, $i, $p - $i ), $color );
      while ( $p < $l && substr( $s, $p, 1 ) eq ' ' ) {
        ++$p;
      }
      if ( $p < $l && substr( $s, $p, 1 ) eq "\n" ) {
        $center = 0;
        ++$p;
      }
    } #/ if ( $p < $l )
    $self->writeLine( 0, $y++, $self->{size}{x}, 1, $b );
  } #/ while ( $y < $self->{size...})
  return;
} #/ sub draw

my $palette;
sub getPalette {    # $palette ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $palette ||= TPalette->new(
    data => cpStaticText, 
    size => length( cpStaticText ),
  );
  return $palette->clone();
}

sub getText {    # void ($s)
  my ( $self, undef ) = @_;
  alias: for my $s ( $_[1] ) {
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( !ref $s and !readonly $s );
  if ( !$self->{text} ) {
    $s = '';
  }
  else {
    $s = substr( $self->{text}, 0, 255 );
  }
  return;
  } #/ alias: for my $s ( $_[1] )
} #/ sub getText

1

__END__

=pod

=head1 NAME

TStaticText - displays fixed text inside a Turbo Vision dialog

=head1 SYNOPSIS

  use TV::Dialogs;

  my $staticText = TStaticText->new(bounds => $bounds, text => "Hello World");
  $staticText->draw();

=head1 DESCRIPTION

C<TStaticText> implements a simple non-editable text display control.  
It stores a text string and renders it inside the given rectangular bounds.  

The control supports multiline behavior and basic centering markers. 

=head1 ATTRIBUTES

=over

=item text

The current text of the static text (I<Str>).

=back

=head1 METHODS

=head2 new

Creates a new C<TStaticText> object with the given bounds and text.

=over

=item bounds

The bounds of the static text (I<TRect>).

=item text

The text for the static text (I<Str>).

=back

=head2 new_TStaticText

 my $obj = new_TStaticText($bounds, $aText);

Convenience constructor that instantiates a static text control from C<$bounds> 
and C<$aText>.

=head2 getText

 $self->getText($s);

Retrieves the internal text and writes it into the supplied scalar.

=head2 draw

 $self->draw();

Renders the control contents into the view's drawing buffer.

=head2 getPalette

 my $palette = $self->getPalette();

Returns the palette used for drawing a static text control.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution).

=cut
