package TV::App::Application;

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

sub BUILD {    # void (| \%args)
  assert ( blessed $_[0] );
  initHistory();
  return;
}

sub DEMOLISH {    # void ()
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
