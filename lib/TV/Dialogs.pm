package TV::Dialogs;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TV::Dialogs::Const;
use TV::Dialogs::Dialog;

sub import {
  my $target = caller;
  TV::Dialogs::Const->import::into( $target, qw( :all ) );
  TV::Dialogs::Dialog->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TV::Dialogs::Const->unimport::out_of( $caller );
  TV::Dialogs::Dialog->unimport::out_of( $caller );
}

1
