package TV::Dialogs::HistInit;
# ABSTRACT: Provides a simple initializer for creating list viewer objects.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THistInit
  new_THistInit
);

use PerlX::Assert::PP;
use TV::toolkit;
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw( :types );

sub THistInit() { __PACKAGE__ }
sub new_THistInit { __PACKAGE__->from(@_) }

# private attributes
has createListViewer => ( is => 'bare', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      createListViewer => CodeRef, { alias => 'cListViewer' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return $args;
}

sub from {    # $init ($cListViewer)
  state $sig = signature(
    method => 1,
    pos    => [CodeRef],
  );
  my ( $class, $cListViewer ) = $sig->( @_ );
  return $class->new( cListViewer => $cListViewer );
}

sub createListViewer {    # $listViewer ($r, $win, $historyId)
  state $sig = signature(
    method => Object,
    pos    => [Object, Object, PositiveOrZeroInt],
  );
  my ( $self, $r, $win, $historyId ) = $sig->( @_ );
  my ( $class, $code ) = ( ref $self, $self->{createListViewer} );
  return $class->$code( $r, $win, $historyId );
}

1

__END__

=pod

=head1 NAME

TV::Dialogs::HistInit - Provides a initializer for creating list viewer objects.

=head1 SYNOPSIS

  package MyHistoryWindow;

  use MyListViewer;
  use TV::Dialogs::HistInit;

  # Callback creating a list viewer
  my $cb = sub {
    my ($extent, $win, $historyId) = @_;
    return MyListViewer->new(
      bounds    => $extent,
      owner     => $win,
      historyId => $historyId,
    );
  };

  # Used in our window class
  sub new {
    ...
    my $historyId = $args->{historyId};
    my $extent = $self->getExtent();

    # Initializer object
    my $init = THistInit->new(cListViewer => $cb);
    my $listViewer = $init->createListViewer($extent, $self, $historyId);
    $self->insert($listViewer);
    ...
  }

=head1 DESCRIPTION

This module provides a initializer for Turbo Vision dialogs that delegates list 
viewer creation to a user-supplied callback. It aims to keep dialog 
initialization flexible while maintaining a clean and minimal interface.

=head1 METHODS

=head2 new

 my $init = TDialog->new(%args);

Creates a new instance of the class using named parameters.

=over

=item cListViewer

A user-supplied callback (I<CodeRef>) that is invoked whenever a list viewer 
instance needs to be created.

=back

=head2 createListViewer

 my $listViewer = $self->createListViewer($r, $win, $historyId);

Calls the user-defined callback to construct a list viewer object. 

=head2 new_THistInit

 my $init = new_THistInit($cListViewer);

Creates a new instance using a positional argument for the callback, providing.

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
