package TV::App::Application;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TApplication
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
