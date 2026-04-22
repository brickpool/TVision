package TV::Views::DrawBuffer;
# ABSTRACT: TDrawBuffer stores a line of text for output in Turbo Vision 2.0.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TDrawBuffer
  new_TDrawBuffer
);

use TV::toolkit qw( :utils );
use TV::toolkit::Types qw(
  :is
  :types
);

sub TDrawBuffer() { __PACKAGE__ }
sub new_TDrawBuffer { __PACKAGE__->from(@_) }

use TV::Views::Const qw( maxViewWidth );

my $setAttr = sub {    # void ($cell, $attr)
  assert ( @_ == 2 );
  assert ( is_PositiveOrZeroInt $_[0] );
  assert ( is_PositiveOrZeroInt $_[1] );
  $_[0] = ( ( $_[1] & 0xff ) << 8 ) | $_[0] & 0xff;
  return;
};

my $getChar = sub {    # $ch ($cell)
  assert ( @_ == 1 );
  assert ( is_PositiveOrZeroInt $_[0] );
  $_[0] & 0xff;
};

my $setChar = sub {    # void ($cell, $ch)
  assert ( @_ == 2 );
  assert ( is_PositiveOrZeroInt $_[0] );
  assert ( is_PositiveOrZeroInt $_[1] );
  $_[0] = $_[0] & 0xff00 | $_[1] & 0xff;
  return;
};

my $setCell = sub {    # void ($cell, $ch, $attr)
  assert ( @_ == 3 );
  assert ( is_PositiveOrZeroInt $_[0] );
  assert ( is_PositiveOrZeroInt $_[1] );
  assert ( is_PositiveOrZeroInt $_[2] );
  $_[0] = ( ( $_[2] & 0xff ) << 8 ) | $_[1] & 0xff;
  return;
};

sub new {    # $obj ()
  state $sig = signature(
    method => 1,
    pos    => [],
  );
  my ( $class ) = $sig->( @_ );
  my $self  = [ ( 0 ) x maxViewWidth ];
  return bless $self, $class;
}

sub from {    # $obj ()
  goto &new;
}

sub putAttribute {    # void ($indent, $attr)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, PositiveOrZeroInt],
  );
  my ( $self, $indent, $attr ) = $sig->( @_ );
  $setAttr->( $self->[$indent], $attr );
  return;
}

sub putChar {    # void ($indent, $c)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Str],
  );
  my ( $self, $indent, $c ) = $sig->( @_ );
  assert ( length $c );
  $setChar->( $self->[$indent], ord( $c ) );
  return;
}

sub moveBuf {    # void ($indent, \@source, $attr, $count)
  state $sig = signature(
    method => Object,
    pos    => [
      PositiveOrZeroInt, 
      ArrayLike, 
      PositiveOrZeroInt, 
      PositiveOrZeroInt,
    ],
  );
  my ( $self, $indent, $source, $attr, $count ) = $sig->( @_ );

  if ( $attr ) {
    for ( my $i = 0 ; $i < $count ; $i++ ) {
      $setCell->( $self->[ $indent + $i ], $getChar->( $source->[$i] ), $attr );
    }
  }
  else {
    for ( my $i = 0 ; $i < $count ; $i++ ) {
      $self->[ $indent + $i ] = $source->[$i];
    }
  }
  return;
} #/ sub moveBuf

sub moveChar {    # void ($indent, $c, $attr, $count)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Str, PositiveOrZeroInt, PositiveOrZeroInt],
  );
  my ( $self, $indent, $c, $attr, $count ) = $sig->( @_ );
  assert ( length $c );

  my $dest = $indent;
  while ( $count-- ) {
    if ( $attr ) {
      if ( $c ) {
        $setCell->( $self->[ $dest++ ], ord( $c ), $attr );
      } 
      else {
        $setAttr->( $self->[ $dest++ ], $attr );
      }
    }
    else {
      $setChar->( $self->[ $dest++ ], ord( $c ) );
    }
  }
  return;
} #/ sub moveChar

sub moveCStr {    # void ($indent, $str, $attrs)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Str, PositiveOrZeroInt],
  );
  my ( $self, $indent, $str, $attrs ) = $sig->( @_ );
  my $toggle  = 1;
  my $curAttr = $attrs & 0xff;

  my $dest = $indent;
  foreach my $c ( split //, $str ) {
    if ( $c eq '~' ) {
      $curAttr = ( $attrs >> ( 8 * $toggle ) ) & 0xff;
      $toggle  = 1 - $toggle;
    }
    else {
      $setCell->( $self->[ $dest++ ], ord( $c ), $curAttr );
    }
  } #/ foreach my $c ( split //, $str)
  return;
} #/ sub moveCStr

sub moveStr {    # void ($indent, $str, $attrs)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Str, PositiveOrZeroInt],
  );
  my ( $self, $indent, $str, $attrs ) = $sig->( @_ );

  my $dest = $indent;
  foreach my $c ( split //, $str ) {
    if ( $attrs ) {
      $setCell->( $self->[ $dest++ ], ord( $c ), $attrs );
    }
    else {
      $setChar->( $self->[ $dest++ ], ord( $c ) );
    }
  }
}

1

__END__

=pod

=head1 NAME

TDrawBuffer - stores a line of text for output in Turbo Vision 2.0.

=head1 SYNOPSIS

  use TV::Views;

  my $buffer = TDrawBuffer->new();
  $buffer->moveStr(0, 'Financial Results for FY1991', $view->getColor(1));
  $view->writeLine(1, 3, 28, 1, $buffer);

=head1 DESCRIPTION

TDrawBuffer stores a line of text for screen output, with each word's low byte 
holding the character value and the high byte holding the video attribute.

=head1 METHODS

=head2 new

  my $obj = TDrawBuffer->new();

Creates a new object instance.

=head2 from

  my $obj = TDrawBuffer->from();

An alternative constructor to L</new> that uses positional parameters.

=head2 moveBuf

  $self->moveBuf($indent, \@source, $attr, $count);

Moves a buffer of characters with specified attributes.

=head2 moveCStr

  $self->moveCStr($indent, $str, $attrs);

Moves a Tilde style string with specified attributes.

=head2 moveChar

  $self->moveChar($indent, $c, $attr, $count);

Moves a single character with specified attributes.

=head2 moveStr

  $self->moveStr($indent, $str, $attrs);

Moves a string with specified attributes.

=head2 putAttribute

  $self->putAttribute($indent, $attr);

Sets the attribute at a specified position.

=head2 putChar

  $self->putChar($indent, $c);

Places a character at a specified position.

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
