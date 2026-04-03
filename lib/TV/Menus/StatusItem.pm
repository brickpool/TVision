package TV::Menus::StatusItem;
# ABSTRACT: Class linking text, hot key, and command for use on a status line 

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStatusItem
  new_TStatusItem
);

use PerlX::Assert::PP;
use TV::toolkit;
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

sub TStatusItem() { __PACKAGE__ }
sub new_TStatusItem { __PACKAGE__->from(@_) }

# public attributes
has next    => ( is => 'rw' );
has text    => ( is => 'rw', default => sub { die 'required' } );
has keyCode => ( is => 'rw', default => sub { die 'required' } );
has command => ( is => 'rw', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      text    => Str,               { alias    => 'aText' },
      keyCode => PositiveOrZeroInt, { alias    => 'key' },
      command => PositiveOrZeroInt, { alias    => 'cmd' },
      next    => Maybe[Object],     { default => undef },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return $args;
}

sub from {    # $obj ($aText, $key, $cmd, |$aNext)
  state $sig = signature(
    method => 1,
    pos => [
      Str,
      PositiveOrZeroInt,
      PositiveOrZeroInt,
      Maybe[Object], { default => undef },
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( text => $args[0], keyCode => $args[1], 
    command => $args[2], next => $args[3] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  undef $self->{text};
  return;
}

1

__END__

=pod

=head1 NAME

TV::Menus::StatusItem - defines the class TStatusItem

=cut
