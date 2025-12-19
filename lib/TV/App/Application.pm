package TV::App::Application;
# ABSTRACT: TApplication is a generic application as a basis for your own apps.

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TApplication
  new_TApplication
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );

use TV::App::Program;
use TV::Dialogs::History::HistList qw(
  initHistory
  doneHistory
);
use TV::Drivers::EventQueue;
use TV::Drivers::Screen;
use TV::Drivers::SystemError;
use TV::toolkit;

sub TApplication() { __PACKAGE__ }
sub new_TApplication { __PACKAGE__->from(@_) }

extends TProgram;

sub BUILD {    # void (|\%args)
  assert ( blessed $_[0] );
  initHistory();
  return;
}

sub DEMOLISH {    # void ($in_global_destruction)
  assert ( @_ == 2 );
  assert ( blessed $_[0] );
  doneHistory();
  return;
}

sub suspend {
  TSystemError->suspend();
  TEventQueue->suspend();
  TScreen->suspend();
  # TVMemMgr->suspend();    # Release discardable memory.
  return;
}

sub resume {
  TScreen->resume();
  TEventQueue->resume();
  TSystemError->resume();
  return;
}

1

__END__

=pod

=head1 NAME

TV::App::Application - a generic application class as a basis for your own apps.

=head1 DESCRIPTION

The TApplication object is the generic application from which most of the Turbo 
Vision programs you write will be derived.

=head1 METHODS

=head2 BUILD

  $self->BUILD( | \%args);

Calls initHistory.

=head2 DEMOLISH

  $self->DEMOLISH($in_global_destruction);

Calls doneHistory.

=head2 resume

  $self->resume();

Calls TSystemError->resume(), TEventQueue->resume(), TScreen->resume().

=head2 suspend

  $self->suspend();

Calls TSystemError->suspend(), TEventQueue->suspend(), TScreen->suspend(), 
TVMemMgr->suspend().

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
