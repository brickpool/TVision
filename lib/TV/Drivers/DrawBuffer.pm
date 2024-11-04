package TV::Drivers::DrawBuffer;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TDrawBuffer
);

sub TDrawBuffer() { __PACKAGE__ }

use TV::Const qw( MAX_VIEW_WIDTH );

sub new {    # $obj ()
  my $class = shift;
  my $self  = [ ( 0 ) x MAX_VIEW_WIDTH ];
  return bless $self, $class;
}

sub putAttribute {    # void ($indent, $attr)
  my ( $self, $indent, $attr ) = @_;
  $self->[$indent] = ( $self->[$indent] & 0x00ff ) | ( $attr << 8 );
  return;
}

sub putChar {    # void ($indent, $c)
  my ( $self, $indent, $c ) = @_;
  $self->[$indent] = ( $self->[$indent] & 0xff00 ) | $c;
  return;
}

sub moveBuf {    # void ($indent, \%source, $attr, $count)
  my ( $self, $indent, $source, $attr, $count ) = @_;

  if ( $attr ) {
    for ( my $i = 0 ; $i < $count ; $i++ ) {
      $self->[ $indent + $i ] = ( $source->[$i] & 0x00ff ) | ( $attr << 8 );
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

  if ( $attr ) {
    for ( my $i = 0 ; $i < $count ; $i++ ) {
      $self->[ $indent + $i ] = ( $c & 0x00ff ) | ( $attr << 8 );
    }
  }
  else {
    for ( my $i = 0 ; $i < $count ; $i++ ) {
      $self->[ $indent + $i ] = $c;
    }
  }
  return;
} #/ sub moveChar

sub moveCStr {    # void ($indent, $str, $attrs)
	my ( $self, $indent, $str, $attrs ) = @_;
	my $toggle  = 1;
	my $curAttr = $attrs & 0x00ff;

	my $i = 0;
	foreach my $c ( split //, $str ) {
		if ( $c eq '~' ) {
			$curAttr = ( $attrs >> ( 8 * $toggle ) ) & 0x00ff;
			$toggle  = 1 - $toggle;
		}
		else {
			$self->[ $indent + $i ] = ( ord( $c ) & 0x00ff ) | ( $curAttr << 8 );
			$i++;
		}
	} #/ foreach my $c ( split //, $str)
	return;
} #/ sub moveCStr

sub moveStr {    # void ($indent, $str, $attrs)
	my ( $self, $indent, $str, $attr ) = @_;

	my $i = 0;
	foreach my $c ( split //, $str ) {
		$self->[ $indent + $i ] = ( ord( $c ) & 0x00ff ) | ( $attr << 8 );
		$i++;
	}
}

1
