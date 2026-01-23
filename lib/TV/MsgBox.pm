package TV::MsgBox;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TV::MsgBox::Const;
use TV::MsgBox::MsgBoxText;

sub import {
  my $target = caller;
  TV::MsgBox::Const->import::into( $target, qw( :all ) );
  TV::MsgBox::MsgBoxText->import::into( $target, qw( /^messageBox|inputBox/ ) );
}

sub unimport {
  my $caller = caller;
  TV::MsgBox::Const->unimport::out_of( $caller );
  TV::MsgBox::MsgBoxText->unimport::out_of( $caller );
}

1
