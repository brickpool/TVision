use 5.014;
use warnings;
use Test::More;
use English;

BEGIN {
  use_ok 'TurboVision::Objects::Stream';
}

package TestStream {
  use Moose;
  use Data::Alias;
  use TurboVision::Objects::Const qw( :stXXXX );
  use TurboVision::Objects::Types qw( TStream );

  extends TStream->class;

  has 'buffer' => (
    is        => 'ro',
    isa       => 'Str',
  );
  has 'position' => (
    is        => 'rw',
    isa       => 'Int',
    reader    => 'get_pos',
    writer    => 'seek',
  );
  has 'size' => (
    is        => 'rw',
    isa       => 'Int',
    reader    => 'get_size',
  );

  use constant E2BIG  => 'Argument list too long';
  use constant EINVAL => 'Invalid argument';

  sub init {
    my $class = shift // confess EINVAL;
    my $buf   = shift // confess EINVAL;
    
    return $class->new(
      buffer    => $buf,
      position  => 0,
      size      => length $buf,
    );
  }

  sub read {
    confess E2BIG   if @_ > 3;
    confess EINVAL  if @_ < 3;
          my $self    = $_[0] // confess EINVAL;
    alias my $buf     = $_[1];
          my $count   = $_[2] // $self->error(ST_READ_ERROR, 0);
    alias my $buffer  = $self->{buffer};
    $buf = "\0" x $count;

    return
        if $self->status != ST_OK;

    my $pos = $self->get_pos;
    my $n = $self->size - $pos;
    $n = $count if $count < $n;
    if ($n < 0 || $count > $n) {
      $self->error(ST_READ_ERROR, 0);
    }
    elsif ($n > 0) {
      $buf = substr($buffer, $pos, $n);
      $self->seek($pos + $n);
    }
    return;
  }
  
  sub write {
    confess E2BIG   if @_ > 3;
    confess EINVAL  if @_ < 3;
          my $self    = $_[0] // confess EINVAL;
    alias my $buf     = $_[1] // $self->error(ST_WRITE_ERROR, 0);
          my $count   = $_[2] // $self->error(ST_WRITE_ERROR, 0);
    alias my $buffer  = $self->{buffer};

    return
        if $self->status != ST_OK;

    my $pos = $self->get_pos;
    my $n = length($buf) - $count;
    $n = $count if $n >= 0;
    if ($n < 0) {
      $self->error(ST_WRITE_ERROR, 0);
    }
    elsif ($n > 0) {
      substr($buffer, $pos) = substr($buf, 0, $n);
      $self->seek($pos + $n);
      $self->size(length $buffer);
    }
    return;
  }
  
  no Moose;
}

use TurboVision::Objects::Const qw( :stXXXX );
use TurboVision::Objects::Types qw( TStream is_TStream );

my $obj = TStream->init();
isa_ok( $obj, TStream->class );

ok( is_TStream($obj), 'is_TStream' );

TStream->stream_error( sub {
  my $self = shift;
  die sprintf("Catch stream status %d and error info %d\n", $self->status, $self->error_info);
  return;
} );

eval { $obj->error(ST_ERROR, 1) };
like(
  $EVAL_ERROR,
  qr/^Catch stream/,
  'TStream->stream_error'
);

$obj->reset();
is(
  $obj->status,
  ST_OK,
  'TStream->reset'
);

my $str = 'Test data.';
$obj = TestStream->init( pack('CA*', length($str), $str) );
$obj->seek($obj->get_size -1);
is(
  $obj->get_pos,
  length($str),
  'TStream->get_size, seek && get_pos'
);

$obj->write('!', 1);
$obj->seek(0);
like(
  $obj->read_str(),
  qr/[!]\z/,
  'TStream->write, read && read_str'
);

my $pos = $obj->get_pos;
$obj->str_write('Ok!');
$obj->seek($pos);
cmp_ok(
  $obj->str_read(), 'eq', 'Ok!',
  'TStream->str_write && str_read'
);

is(
  $obj->status,
  ST_OK,
  'TStream->status'
);

done_testing;
