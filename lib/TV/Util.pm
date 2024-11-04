=pod

=head1 DESCRIPTION

defines various utility functions used throughout Turbo Vision

=cut

package TV::Util;

use Exporter 'import';

our @EXPORT_OK = qw(
  message
);

use TV::Drivers::Const qw( EV_NOTHING );
use TV::Drivers::Event;

sub message {    # $view|undef ($receiver, $what, $command, $infoPtr)
	my ( $receiver, $what, $command, $infoPtr ) = @_;

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

	if ( $event->{what} == EV_NOTHING ) {
		return $event->{message}{infoPtr};
	}
	else {
		return undef;
	}
} #/ sub message

1
