package TV::Menus::MenuItem;
# ABSTRACT: Class linking text, hot key, command, and help for use within a menu

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMenuItem
  newLine
  new_TMenuItem
);

use Carp ();
use Scalar::Util qw( looks_like_number );
use TV::toolkit;
use TV::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

use TV::Views::Const qw( hcNoContext );
use TV::Views::View;

sub TMenuItem() { __PACKAGE__ }
sub new_TMenuItem { __PACKAGE__->from(@_) }

# public attributes
has next     => ( is => 'rw' );
has name     => ( is => 'rw', default => sub { die 'required' } );
has command  => ( is => 'rw', default => 0 );
has disabled => ( is => 'rw', default => false );
has keyCode  => ( is => 'rw', default => sub { die 'required' }  );
has helpCtx  => ( is => 'rw', default => hcNoContext );
has param    => ( is => 'rw', default => '' );
has subMenu  => ( is => 'rw' );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      name    => Str,               { alias => 'aName' },
      keyCode => PositiveOrZeroInt, { alias => 'aKeyCode' },
      command => PositiveOrZeroInt, { alias => 'aCommand', optional => 1 },
      subMenu => Maybe[Object],     { alias => 'aSubMenu', optional => 1 },
      helpCtx => PositiveOrZeroInt, { alias => 'aHelpCtx', optional => 1 },
      param   => Str,               { alias => 'p',        optional => 1 },
      next    => Maybe[Object],     { alias => 'aNext',    optional => 1 },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{disabled} = !TView->commandEnabled( $self->{command} );
  return;
}

sub from {    # $obj ($aName, |$aCommand, $aKeyCode, |$aSubMenu, $aHelpCtx, |$p, |$aNext)
  if ( looks_like_number $_[3] ) {
    state $sig = signature(
      method => 1,
      pos    => [
        Str,
        PositiveOrZeroInt,
        PositiveOrZeroInt,
        PositiveOrZeroInt, { default => hcNoContext },
        Str,               { default => '' },
        Maybe[Object],     { default => undef },
      ],
    );
    my ( $class, @args ) = $sig->( @_ );
    return $class->new( name => $args[0], command => $args[1], 
      keyCode => $args[2], helpCtx => $args[3], param => $args[4], 
        next => $args[6] );
  } 
  else {
    state $sig = signature(
      method => 1,
      pos    => [
        Str,
        PositiveOrZeroInt,
        Maybe[Object],
        PositiveOrZeroInt, { default => hcNoContext },
        Maybe[Object],     { default => undef },
      ],
    );
    my ( $class, @args ) = $sig->( @_ );
    return $class->new( name => $args[0], keyCode => $args[1], 
      subMenu => $args[2], helpCtx => $args[3], next => $args[4] );
  }
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  undef $self->{name};
  if ( $self->{command} == 0 ) {
    undef $self->{subMenu};
  }
  else {
    undef $self->{param};
  }
  return;
}

sub append {    # void ($aNext)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $aNext ) = $sig->( @_ );
  $self->{next} = $aNext;
  return;
}

sub newLine () {    # $menuItem ()
  return TMenuItem->new(
    name    => '',
    command => 0,
    keyCode => 0,
    helpCtx => hcNoContext,
    param   => '',
    next    => undef,
  );
}

1

__END__

=pod

=head1 NAME

TV::Menus::MenuItem - defines the class TMenuItem

=cut
