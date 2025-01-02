=pod

=head1 DESCRIPTION

defines various utility functions used throughout Turbo Vision

=cut

package TV::Views::Util;

use strict;
use warnings;

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
