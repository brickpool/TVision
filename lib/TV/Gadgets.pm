package TV::Gadgets;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TV::Gadgets::Const;
use TV::Gadgets::PrintConstants;
use TV::Gadgets::ClockView;
use TV::Gadgets::EventViewer;
use TV::Gadgets::HeapView;

sub import {
  my $target = caller;
  TV::Gadgets::Const->import::into( $target, qw( :all ) );
  TV::Gadgets::PrintConstants->import::into( $target );
  TV::Gadgets::ClockView->import::into( $target );
  TV::Gadgets::EventViewer->import::into( $target );
  TV::Gadgets::HeapView->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TV::Gadgets::Const->unimport::out_of( $caller );
  TV::Gadgets::PrintConstants->unimport::out_of( $caller );
  TV::Gadgets::ClockView->unimport::out_of( $caller );
  TV::Gadgets::EventViewer->unimport::out_of( $caller );
  TV::Gadgets::HeapView->unimport::out_of( $caller );
}

1
