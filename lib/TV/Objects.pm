package TV::Objects;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TV::Objects::Const;
use TV::Objects::Object;
use TV::Objects::Point;
use TV::Objects::Rect;
use TV::Objects::DrawBuffer;
use TV::Objects::NSCollection;
use TV::Objects::NSSortedCollection;
use TV::Objects::Collection;
use TV::Objects::SortedCollection;

sub import {
  my $target = caller;
  TV::Objects::Const->import::into( $target, qw( :all ) );
  TV::Objects::Object->import::into( $target );
  TV::Objects::Point->import::into( $target );
  TV::Objects::Rect->import::into( $target );
  TV::Objects::DrawBuffer->import::into( $target );
  TV::Objects::NSCollection->import::into( $target );
  TV::Objects::NSSortedCollection->import::into( $target );
  TV::Objects::Collection->import::into( $target );
  TV::Objects::SortedCollection->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TV::Objects::Const->unimport::out_of( $caller );
  TV::Objects::Object->unimport::out_of( $caller );
  TV::Objects::Point->unimport::out_of( $caller );
  TV::Objects::Rect->unimport::out_of( $caller );
  TV::Objects::DrawBuffer->unimport::out_of( $caller );
  TV::Objects::NSCollection->unimport::out_of( $caller );
  TV::Objects::NSSortedCollection->unimport::out_of( $caller );
  TV::Objects::Collection->unimport::out_of( $caller );
  TV::Objects::SortedCollection->unimport::out_of( $caller );
}

1
