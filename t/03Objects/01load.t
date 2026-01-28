#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Objects::Const';
  use_ok 'TV::Objects::Object';
  use_ok 'TV::Objects::Point';
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Objects::NSCollection';
  use_ok 'TV::Objects::NSSortedCollection';
  use_ok 'TV::Objects::Collection';
  use_ok 'TV::Objects::SortedCollection';
  use_ok 'TV::Objects::StringCollection';
}

isa_ok( TObject->new(), TObject );
isa_ok( TPoint->new(), TPoint );
isa_ok( TRect->new(), TRect );
isa_ok( TNSCollection->new(), TNSCollection );
isa_ok( TNSSortedCollection->new(), TNSSortedCollection );
isa_ok( TCollection->new(), TCollection );
isa_ok( TSortedCollection->new(), TSortedCollection );
isa_ok( TStringCollection->new(), TStringCollection );
