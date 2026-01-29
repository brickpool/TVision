package TV::Dialogs;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TV::Dialogs::Const;
use TV::Dialogs::Button;
use TV::Dialogs::Cluster;
use TV::Dialogs::Dialog;
use TV::Dialogs::InputLine;
use TV::Dialogs::Label;
use TV::Dialogs::ParamText;
use TV::Dialogs::StaticText;
use TV::Dialogs::StrItem;
use TV::Dialogs::RadioButtons;
use TV::Dialogs::Util;
use TV::Dialogs::History::HistList;

sub import {
  my $target = caller;
  TV::Dialogs::Const->import::into( $target, qw( :all ) );
  TV::Dialogs::Util->import::into( $target, qw( /\S+/) );
  TV::Dialogs::Button->import::into( $target );
  TV::Dialogs::Cluster->import::into( $target );
  TV::Dialogs::Dialog->import::into( $target );
  TV::Dialogs::InputLine->import::into( $target );
  TV::Dialogs::Label->import::into( $target );
  TV::Dialogs::ParamText->import::into( $target );
  TV::Dialogs::RadioButtons->import::into( $target );
  TV::Dialogs::StaticText->import::into( $target );
  TV::Dialogs::StrItem->import::into( $target );
  TV::Dialogs::Util->import::into( $target, qw( /\S+/) );
  TV::Dialogs::History::HistList->import::into( $target, qw( /\S+/) );
}

sub unimport {
  my $caller = caller;
  TV::Dialogs::Const->unimport::out_of( $caller );
  TV::Dialogs::Button->unimport::out_of( $caller );
  TV::Dialogs::Cluster->unimport::out_of( $caller );
  TV::Dialogs::Dialog->unimport::out_of( $caller );
  TV::Dialogs::InputLine->unimport::out_of( $caller );
  TV::Dialogs::Label->unimport::out_of( $caller );
  TV::Dialogs::ParamText->unimport::out_of( $caller );
  TV::Dialogs::RadioButtons->unimport::out_of( $caller );
  TV::Dialogs::StaticText->unimport::out_of( $caller );
  TV::Dialogs::StrItem->unimport::out_of( $caller );
  TV::Dialogs::Util->unimport::out_of( $caller );
  TV::Dialogs::History::HistList::out_of( $caller );
}

1
