package TV::Views::Util;
# ABSTRACT: defines various utility functions used throughout Turbo Vision

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT_OK = qw(
  message
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Drivers::Const qw( evNothing );
use TV::Drivers::Event;

sub message {    # $view|undef ($receiver|undef, $what, $command, $infoPtr)
  assert ( @_ == 4 );
  my ( $receiver, $what, $command, $infoPtr ) = @_;
  assert ( !defined $receiver or blessed $receiver );
  assert ( looks_like_number $what );
  assert ( looks_like_number $command );

  return undef
    unless $receiver;

  my $event = TEvent->new(
    what    => $what,
    message => {
      command => $command,
      infoPtr => $infoPtr,
    },
  );

  $receiver->handleEvent( $event );

  if ( $event->{what} == evNothing ) {
    return $event->{message}{infoPtr};
  }
  else {
    return undef;
  }
} #/ sub message

1

__END__

=pod

=head1 NAME

TV::Views::Util

=head1 DESCRIPTION

Defines utility functions used throughout Turbo Vision.

=head1 FUNCTIONS

=head2 message

  my $view | undef = message($receiver | undef, $what, $command, $infoPtr);

Sends a message to a specified receiver and returns the view that handled the
message, or C<undef> if no view handled it.

=over

=item $receiver

The target view that will receive the message. If C<undef>, the message is sent
to the current view. (TView | undef)

=item $what

The type of message being sent. This parameter specifies the category or
purpose of the message. (Int)

=item $command

The specific command associated with the message. This parameter defines the
action to be taken by the receiver. (Int)

=item $infoPtr

A reference to additional information related to the message. This can be used 
to pass extra data required for handling the message. (Ref)

=back

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2025 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
