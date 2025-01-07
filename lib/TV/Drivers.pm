package TV::Drivers;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TV::Drivers::Const;
use TV::Drivers::HardwareInfo;
use TV::Drivers::Display;
use TV::Drivers::Screen;
use TV::Drivers::SystemError;
use TV::Drivers::Event;
use TV::Drivers::HWMouse;
use TV::Drivers::Mouse;
use TV::Drivers::EventQueue;
use TV::Drivers::Util;

sub import {
  my $target = caller;
  TV::Drivers::Const->import::into( $target, qw( :all ) );
  TV::Drivers::HardwareInfo->import::into( $target );
  TV::Drivers::Display->import::into( $target );
  TV::Drivers::Screen->import::into( $target );
  TV::Drivers::SystemError->import::into( $target );
  TV::Drivers::Event->import::into( $target );
  TV::Drivers::HWMouse->import::into( $target );
  TV::Drivers::Mouse->import::into( $target );
  TV::Drivers::EventQueue->import::into( $target );
  TV::Drivers::Util->import::into( $target, qw( /.+/) );
}

sub unimport {
  my $caller = caller;
  TV::Drivers::Const->unimport::out_of( $caller );
  TV::Drivers::HardwareInfo->unimport::out_of( $caller );
  TV::Drivers::Display->unimport::out_of( $caller );
  TV::Drivers::Screen->unimport::out_of( $caller );
  TV::Drivers::SystemError->unimport::out_of( $caller );
  TV::Drivers::Event->unimport::out_of( $caller );
  TV::Drivers::HWMouse->unimport::out_of( $caller );
  TV::Drivers::Mouse->unimport::out_of( $caller );
  TV::Drivers::EventQueue->unimport::out_of( $caller );
  TV::Drivers::Util->unimport::out_of( $caller );
}

1
