package TV::Menus::SubMenu;
# ABSTRACT: Class for a submenu off a menu bar or menu box 

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TSubMenu
  new_TSubMenu
);

use PerlX::Assert::PP;
use TV::toolkit;
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  is_Object
  :types
);

use TV::Views::Const qw( hcNoContext );
use TV::Menus::Menu;
use TV::Menus::MenuItem;

sub TSubMenu() { __PACKAGE__ }
sub new_TSubMenu { __PACKAGE__->from(@_) }

extends TMenuItem;

# predeclare private methods
my (
  $add_menu_item,
  $add_sub_menu,
);

sub from {    # $obj ($nm, $key, |$helpCtx)
  state $sig = signature(
    method => 1,
    pos    => [
      Str,
      PositiveOrZeroInt,
      PositiveOrZeroInt, { default => hcNoContext },
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( name => $args[0], keyCode => $args[1], 
    helpCtx => $args[2] );
}

sub _add_menu_item { goto &$add_menu_item }
$add_menu_item = sub {    # $s ($s, $i, |undef)
  my ( $s, $i ) = @_;
  assert ( @_ >= 2 && @_ <= 3 );
  assert ( is_Object $s );
  assert ( is_Object $i and $i->isa( TMenuItem ) );
  my $sub = $s;
  while ( $sub->{next} ) {
    $sub = $sub->{next};
  }

  if ( !$sub->{subMenu} ) {
    $sub->{subMenu} = TMenu->new( items => $i );
  }
  else {
    my $cur = $sub->{subMenu}{items};
    while ( $cur->{next} ) {
      $cur = $cur->{next};
    }
    $cur->{next} = $i;
  }
  return $s;
}; #/ sub $add_menu_item

sub _add_sub_menu { goto &$add_sub_menu }
$add_sub_menu = sub {    # $s1 ($s1, $s2, |undef)
  my ( $s1, $s2 ) = @_;
  assert ( @_ >= 2 && @_ <= 3 );
  assert ( is_Object $s1 );
  assert ( is_Object $s2 and $s2->isa( TSubMenu ) );
  my $cur = $s1;
  while ( $cur->{next} ) {
    $cur = $cur->{next};
  }
  $cur->{next} = $s2;
  return $s1;
};

sub add {    # $s ($s1, $s2|$i, |$swap)
  state $sig = signature(
    pos => [
      Object,
      Object,
      Bool, { optional => 1 } 
    ],
  );
  my ( $s1, $s2, $swap ) = $sig->( @_ );
  assert ( not $swap );    # test if operands have been swapped
  $s2->isa( TSubMenu )
    ? goto &$add_sub_menu
    : goto &$add_menu_item
}

use overload
  '+' => \&add,
  fallback => 1;

1

__END__

=pod

=head1 NAME

TV::Menus::SubMenu - defines the class TSubMenu

=cut
