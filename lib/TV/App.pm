package TV::App;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TV::App::Const;
use TV::App::Background;
use TV::App::DeskInit;
use TV::App::DeskTop;
use TV::App::ProgInit;
use TV::App::Program;
use TV::App::Application;

sub import {
  my $target = caller;
  TV::App::Const->import::into( $target, qw( :all ) );
  TV::App::Background->import::into( $target );
  TV::App::DeskInit->import::into( $target );
  TV::App::DeskTop->import::into( $target );
  TV::App::ProgInit->import::into( $target );
  TV::App::Program->import::into( $target );
  TV::App::Application->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TV::App::Const->unimport::out_of( $caller );
  TV::App::Background->unimport::out_of( $caller );
  TV::App::DeskInit->unimport::out_of( $caller );
  TV::App::DeskTop->unimport::out_of( $caller );
  TV::App::ProgInit->unimport::out_of( $caller );
  TV::App::Program->unimport::out_of( $caller );
  TV::App::Application->unimport::out_of( $caller );
}

1
