package TV::StdDlg::DirEntry;
# ABSTRACT: A directory entry for use in TDirCollection

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TDirEntry
  new_TDirEntry
);

use Devel::StrictMode;
use if STRICT => 'Hash::Util';
use TV::toolkit qw( signature );
use TV::toolkit::Types qw(
  Object
  Str
);

sub TDirEntry() { __PACKAGE__ }
sub new_TDirEntry { __PACKAGE__->from(@_) }

# public attributes
our %HAS; BEGIN {
  %HAS = ( 
    displayText => sub { die 'required' },
    directory   => sub { die 'required' },
  );
}

sub new {    # \$obj (%args)
  state $sig = signature(
    method => 1,
    named  => [
      displayText => Str, { alias => 'txt' },
      directory   => Str, { alias => 'dir' },
    ],
  );
  my ( $class, $args ) = $sig->( @_ );
  my $self = {
    displayText => $args->{displayText} // $HAS{displayText}->(),
    directory   => $args->{directory}   // $HAS{directory}->(),
  };
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
}

sub from {    # $obj ($x, $y)
  state $sig = signature(
    method => 1,
    pos => [Str, Str],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( displayText => $args[0], directory => $args[1] );
}

sub dir  {
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{directory};
}

sub text {
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{displayText};
}

1
