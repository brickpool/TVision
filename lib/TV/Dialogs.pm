package TV::Dialogs;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TV::Dialogs::Const;
use TV::Dialogs::Button;
use TV::Dialogs::Dialog;
use TV::Dialogs::StaticText;
use TV::Dialogs::Util;

sub import {
  my $target = caller;
  TV::Dialogs::Const->import::into( $target, qw( :all ) );
  TV::Dialogs::Button->import::into( $target );
  TV::Dialogs::Dialog->import::into( $target );
  TV::Dialogs::StaticText->import::into( $target );
  TV::Dialogs::Util->import::into( $target, qw( /\S+/) );
}

sub unimport {
  my $caller = caller;
  TV::Dialogs::Const->unimport::out_of( $caller );
  TV::Dialogs::Button->unimport::out_of( $caller );
  TV::Dialogs::Dialog->unimport::out_of( $caller );
  TV::Dialogs::StaticText->unimport::out_of( $caller );
  TV::Dialogs::Util->unimport::out_of( $caller );
}

1
