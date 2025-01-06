package TV::Views;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TV::Views::Const;
use TV::Views::CommandSet;
use TV::Views::Palette;
use TV::Views::View;
use TV::Views::Group;
use TV::Views::Frame;
use TV::Views::ScrollBar;
use TV::Views::WindowInit;
use TV::Views::Window;
use TV::Views::Util;

sub import {
  my $target = caller;
  TV::Views::Const->import::into( $target, qw( :all ) );
  TV::Views::CommandSet->import::into( $target );
  TV::Views::Palette->import::into( $target );
  TV::Views::View->import::into( $target );
  TV::Views::Group->import::into( $target );
  TV::Views::Frame->import::into( $target );
  TV::Views::ScrollBar->import::into( $target );
  TV::Views::WindowInit->import::into( $target );
  TV::Views::Window->import::into( $target );
  TV::Views::Util->import::into( $target, qw( message ) );
}

sub unimport {
  my $caller = caller;
  TV::Views::Const->unimport::out_of( $caller );
  TV::Views::CommandSet->unimport::out_of( $caller );
  TV::Views::Palette->unimport::out_of( $caller );
  TV::Views::View->unimport::out_of( $caller );
  TV::Views::Group->unimport::out_of( $caller );
  TV::Views::Frame->unimport::out_of( $caller );
  TV::Views::ScrollBar->unimport::out_of( $caller );
  TV::Views::WindowInit->unimport::out_of( $caller );
  TV::Views::Window->unimport::out_of( $caller );
  TV::Views::Util->unimport::out_of( $caller );
}

1
