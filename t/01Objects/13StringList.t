use 5.014;
use warnings;
use Test::More;

#--------------------
BEGIN { note 'Init' }
#--------------------

BEGIN {
  require_ok 'TurboVision::Objects::StrListMaker';
  require_ok 'TurboVision::Objects::StringList';
  require_ok 'TurboVision::Objects::Types';
}
use_ok 'TurboVision::Objects::StreamRec';
use_ok 'TurboVision::Objects::MemoryStream';
use_ok 'TurboVision::Objects::ResourceFile';

use TurboVision::Objects::Const qw(
  ST_OK
);
use TurboVision::Objects::StringList qw( RStringList );
use TurboVision::Objects::StrListMaker qw( RStrListMaker );
use TurboVision::Objects::Types qw(
  TStreamRec
  TMemoryStream
  TResourceFile
  TStringList
  TStrListMaker
);

use constant S_INFORMATION  => 100;
use constant S_WARNING      => 101;
use constant S_ERROR        => 102;
use constant S_LOADING_FILE => 200;
use constant S_SAVING_FILE  => 201;

my $stream;
$stream = TMemoryStream->init();
isa_ok(
  $stream,
  TMemoryStream->class()
);

#-------------------
note 'StrListMaker';
#-------------------
{
  my ($res_file, $s);
  
  TStreamRec->register_type(RStrListMaker);
  $res_file = TResourceFile->init( $stream );
  isa_ok(
    $res_file,
    TResourceFile->class()
  );
  $s = TStrListMaker->init(16384, 256);
  isa_ok(
    $s,
    TStrListMaker->class()
  );
  $s->put(S_INFORMATION, 'Information');
  $s->put(S_WARNING, 'Warning');
  $s->put(S_ERROR, 'Error');
  $s->put(S_LOADING_FILE, 'Loading file %s.');
  $s->put(S_SAVING_FILE, 'Saving file %s,');
  
  $res_file->put($s, 'Strings');
  is(
    $stream->status,
    ST_OK,
    'TMemoryStream->status'
  );
}

#------------
note 'Reset';
#------------
$stream->seek(0);
is(
  $stream->status,
  ST_OK,
  'TMemoryStream->status'
);
TStreamRec->_clear_stream_types();
ok(
  !TStreamRec->_has_stream_types(),
  'TStreamRec->register_type'
);

#-----------------
note 'StringList';
#-----------------
{
  my ($res_file, $s);
  
  TStreamRec->register_type(RStringList);
  $res_file = TResourceFile->init( $stream );
  isa_ok(
    $res_file,
    TResourceFile->class()
  );
  $s = $res_file->get('Strings');
  isa_ok(
    $s,
    TStringList->class()
  );
  is(
    $stream->status,
    ST_OK,
    'TMemoryStream->status'
  );
  like(
    $s->get(S_INFORMATION),
    qr/Information/,
    'TStringList->get(S_INFORMATION)'
  );
  like(
    $s->get(S_ERROR),
    qr/Error/,
    'TStringList->get(S_ERROR)'
  );
  like(
    $s->get(S_LOADING_FILE),
    qr/Loading file/,
    'TStringList->get(S_LOADING_FILE)'
  );
}

done_testing;
