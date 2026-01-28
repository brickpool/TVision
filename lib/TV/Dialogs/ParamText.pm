package TV::Dialogs::ParamText;
# ABSTRACT: displays formatted dynamic text inside a Turbo Vision dialog

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TParamText
  new_TParamText
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

use TV::Dialogs::StaticText;
use TV::toolkit;

sub TParamText()   { __PACKAGE__ }
sub name()         { 'TParamText' }
sub new_TParamText { __PACKAGE__->from( @_ ) }

extends TStaticText;

# declare attributes
has str => ( is => 'ro' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_, text => '' );
  my $args2 = check( {
    str => { default => '', no_override => 1 },
  } => { @_ } ) || Carp::confess( last_error );
  return { %$args1, %$args2 };
}

sub from {    # $obj ($bounds)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 1 );
  return $class->new( bounds => $_[0] );
}

sub getText {    # void ($s)
  my ( $self, undef ) = @_;
  alias: for my $s ( $_[1] ) {
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( !ref $s and !readonly $s );
  $s = defined $self->{str} ? $self->{str} : '';
  return;
  }
} #/ sub getText

sub getTextLen {    # $len ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  return defined $self->{str} ? length $self->{str} : 0;
}

sub setText {    # void ($fmt, @args)
  my ( $self, $fmt, @args ) = @_;
  assert ( @_ >= 2 );
  assert ( blessed $self );
  assert ( defined $fmt and !ref $fmt );
  $self->{str} = sprintf( $fmt, @args );
  $self->drawView();
  return;
} #/ sub setText

1

__END__

=pod

=head1 NAME

TParamText - displays formatted dynamic text inside a Turbo Vision dialog

=head1 SYNOPSIS

  use TV::Objects;
  use TV::Dialogs;

  my $bounds = TRect->new(ax => 1, ay => 1, bx => 30, by => 2);
  my $paramText = TParamText->new(bounds => $bounds);

  $paramText->setText('Value: %d, Name: %s', 42, 'John');

  my $text = '';
  $paramText->getText($text);

  print "Current text: $text\n";
  
=head1 DESCRIPTION

C<TParamText> provides a formatted text control for Turbo Vision dialogs.
It stores a dynamic string buffer and allows updating its content using 
printf‑style formatting.

The control integrates with the Turbo Vision drawing system and refreshes itself 
when the text changes.

=head1 ATTRIBUTES

=over

=item str

The formatted text buffer maintained internally by the control (I<Str>).

=back

=head1 METHODS

=head2 new

 my $paramText = $self->new(%args);

Creates a new C<TParamText> object using the provided constructor arguments and 
initializes its internal buffer.

=over

=item bounds

The bounds of the param text (I<TRect>).

=back

=head2 new_TParamText

 my $paramText = new_TParamText($bounds);

Constructs a C<TParamText> instance from a C<TRect> object as a convenience 
wrapper for simplified creation.

=head2 getText

 $self->getText($s);

Retrieves the current internal text and writes it into the scalar supplied by 
the caller.

=head2 getTextLen

 my $len = $self->getTextLen();

Returns the length of the text currently stored in the internal buffer.

=head2 setText

 $self->setText($fmt, @args);

Formats and stores text using a printf‑style format string and triggers a 
redraw of the view.

=cut

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
