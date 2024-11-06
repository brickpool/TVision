package TV::Drivers::DrawBuffer;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TDrawBuffer
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed 
  looks_like_number
  readonly
);

sub TDrawBuffer() { __PACKAGE__ }

use TV::Const qw( MAX_VIEW_WIDTH );

my $setAttr = sub {    # void ($cell, $attr)
  $_[0] = ( ( $_[1] & 0xff ) << 8 ) | $_[0] & 0xff;
  return;
};

my $getChar = sub {    # $ch ($cell)
  $_[0] & 0xff;
};

my $setChar = sub {    # void ($cell, $ch)
  $_[0] = $_[0] & 0xff00 | $_[1] & 0xff;
  return;
};

my $setCell = sub {    # void ($cell, $ch, $attr)
  $_[0] = ( ( $_[2] & 0xff ) << 8 ) | $_[1] & 0xff;
  return;
};

sub new {    # $obj ()
  my $class = shift;
  assert ( $class and !ref $class );
  my $self  = [ ( 0 ) x MAX_VIEW_WIDTH ];
  return bless $self, $class;
}

sub putAttribute {    # void ($indent, $attr)
  my ( $self, $indent, $attr ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $indent );
  assert ( looks_like_number $attr );
  $setAttr->( $self->[$indent], $attr );
  return;
}

sub putChar {    # void ($indent, $c)
  my ( $self, $indent, $c ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $indent );
  assert ( !ref $c and length $c );
  $setChar->( $self->[$indent], ord( $c ) );
  return;
}

sub moveBuf {    # void ($indent, \@source, $attr, $count)
  my ( $self, $indent, $source, $attr, $count ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $indent );
  assert ( ref $source );
  assert ( looks_like_number $attr );
  assert ( looks_like_number $count );

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
  my ( $self, $indent, $c, $attr, $count ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $indent );
  assert ( !ref $c and length $c );
  assert ( looks_like_number $attr );
  assert ( looks_like_number $count );

  if ( $attr ) {
    for ( my $i = 0 ; $i < $count ; $i++ ) {
      $setCell->( $self->[ $indent + $i ], ord( $c ), $attr );
    }
  }
  else {
    for ( my $i = 0 ; $i < $count ; $i++ ) {
      $setChar->( $self->[ $indent + $i ], ord( $c ) );
    }
  }
  return;
} #/ sub moveChar

sub moveCStr {    # void ($indent, $str, $attrs)
  my ( $self, $indent, $str, $attrs ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $indent );
  assert ( defined $str and !ref $str );
  assert ( looks_like_number $attrs );
  my $toggle  = 1;
  my $curAttr = $attrs & 0xff;

  my $i = 0;
  foreach my $c ( split //, $str ) {
    if ( $c eq '~' ) {
      $curAttr = ( $attrs >> ( 8 * $toggle ) ) & 0xff;
      $toggle  = 1 - $toggle;
    }
    else {
      $setCell->( $self->[ $indent + $i ], ord( $c ), $curAttr );
      $i++;
    }
  } #/ foreach my $c ( split //, $str)
  return;
} #/ sub moveCStr

sub moveStr {    # void ($indent, $str, $attrs)
  my ( $self, $indent, $str, $attr ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $indent );
  assert ( defined $str and !ref $str );
  assert ( looks_like_number $attr );

  my $i = 0;
  foreach my $c ( split //, $str ) {
    $setCell->( $self->[ $indent + $i ], ord( $c ), $attr );
    $i++;
  }
}

1
