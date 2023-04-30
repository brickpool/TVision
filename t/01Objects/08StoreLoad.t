use 5.014;
use warnings;
use Test::More;

BEGIN {
  require_ok 'TurboVision::Objects::Collection';
}

package Local::TNumObject {
  use Moose;
  use TurboVision::Objects::Common qw( word );
  use TurboVision::Objects::StreamRec;
  use TurboVision::Objects::Types qw( TStreamRec );

  use constant RNumObject => TStreamRec->new(
    obj_type  => 100,
    vmt_link  => __PACKAGE__,
    load      => 'load',
    store     => 'store',
  );

  use constant ENODATA  => 'No data available';
  use constant EINVAL   => 'Invalid argument';

  has 'number' => (
    is      => 'rw',
    isa     => 'Int',
    required => 1,
  );

  sub load {
    my $class = shift // confess EINVAL;
    my $s     = shift // confess EINVAL;

    my $number = do {
      $s->read(my $buf, word->size);
      word( $buf )->unpack();
    };
    confess ENODATA if !defined $number;
    return $class->new( number => $number );
  }

  sub store {
    my $self  = shift // confess EINVAL;
    my $s     = shift // confess EINVAL;

    my $buf = word( $self->number )->pack;
    $s->write($buf, word->size);
    return;
  }
  no Moose;

}

INIT {
  use TurboVision::Objects::Types qw( TCollection TStreamRec );

  TStreamRec->register_type(TCollection->RCollection);
  TStreamRec->register_type(Local::TNumObject->RNumObject);
}

package main {
  use TurboVision::Objects::Const qw(
    ST_OK
  );
  use TurboVision::Objects::MemoryStream;
  use TurboVision::Objects::Collection;
  use TurboVision::Objects::Types qw(
    TMemoryStream
    TCollection
  );
  
  my $stream = TMemoryStream->init();
  isa_ok(
    $stream,
    TMemoryStream->class
  );
  
  my $col = TCollection->init();
  isa_ok(
    $col,
    TCollection->class
  );
  
  $col->insert( Local::TNumObject->new(number => $_) ) for (2..4);
  is(
    $col->count,
    3,
    'TCollection->count'
  );
  
  $stream->put($col);
  $stream->seek(0);
  is(
    $stream->status,
    ST_OK,
    'TMemoryStream->put & seek'
  );
  
  $col = $stream->get();
  isa_ok(
    $col,
    TCollection->class
  );
  is(
    $col->count,
    3,
    'TCollection->get & count'
  );

  my $sum = 0;
  $col->for_each( sub { $sum += $_->number if defined } );
  is(
    $sum,
    9,
    'TCollection->for_each'
  );
  
  done_testing;
}
