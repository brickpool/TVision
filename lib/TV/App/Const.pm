package TV::App::Const;

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  cpXXXX => [qw(
    cpBackground
    cpAppColor
    cpAppBlackWhite
    cpAppMonochrome
  )],
  
  hcXXXX => [qw(
    hcNew
    hcOpen
    hcSave
    hcSaveAs
    hcSaveAll
    hcChangeDir
    hcDosShell
    hcExit

    hcUndo
    hcCut
    hcCopy
    hcPaste
    hcClear

    hcTile
    hcCascade
    hcCloseAll
    hcResize
    hcZoom
    hcNext
    hcPrev
    hcClose
  )],

  apXXXX => [qw(
    apColor
    apBlackWhite
    apMonochrome
  )],

);

# add all the other %EXPORT_TAGS ":class" tags to the ":all" class and
# @EXPORT_OK, deleting duplicates
{
  my %seen;
  push
    @EXPORT_OK,
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
        foreach keys %EXPORT_TAGS;
  push
    @{$EXPORT_TAGS{all}},
      @EXPORT_OK;
}

# Turbo Vision 2.0 Color Palettes

use constant cpBackground =>  "\x01";    # background palette

use constant cpAppColor =>
      "\x71\x70\x78\x74\x20\x28\x24\x17\x1F\x1A\x31\x31\x1E\x71\x1F".
  "\x37\x3F\x3A\x13\x13\x3E\x21\x3F\x70\x7F\x7A\x13\x13\x70\x7F\x7E".
  "\x70\x7F\x7A\x13\x13\x70\x70\x7F\x7E\x20\x2B\x2F\x78\x2E\x70\x30".
  "\x3F\x3E\x1F\x2F\x1A\x20\x72\x31\x31\x30\x2F\x3E\x31\x13\x38\x00".
  "\x17\x1F\x1A\x71\x71\x1E\x17\x1F\x1E\x20\x2B\x2F\x78\x2E\x10\x30".
  "\x3F\x3E\x70\x2F\x7A\x20\x12\x31\x31\x30\x2F\x3E\x31\x13\x38\x00".
  "\x37\x3F\x3A\x13\x13\x3E\x30\x3F\x3E\x20\x2B\x2F\x78\x2E\x30\x70".
  "\x7F\x7E\x1F\x2F\x1A\x20\x32\x31\x71\x70\x2F\x7E\x71\x13\x78\x00".
  "\x37\x3F\x3A\x13\x13\x30\x3E\x1E";    # help colors

use constant cpAppBlackWhite =>
      "\x70\x70\x78\x7F\x07\x07\x0F\x07\x0F\x07\x70\x70\x07\x70\x0F".
  "\x07\x0F\x07\x70\x70\x07\x70\x0F\x70\x7F\x7F\x70\x07\x70\x07\x0F".
  "\x70\x7F\x7F\x70\x07\x70\x70\x7F\x7F\x07\x0F\x0F\x78\x0F\x78\x07".
  "\x0F\x0F\x0F\x70\x0F\x07\x70\x70\x70\x07\x70\x0F\x07\x07\x08\x00".
  "\x07\x0F\x0F\x07\x70\x07\x07\x0F\x0F\x70\x78\x7F\x08\x7F\x08\x70".
  "\x7F\x7F\x7F\x0F\x70\x70\x07\x70\x70\x70\x07\x7F\x70\x07\x78\x00".
  "\x70\x7F\x7F\x70\x07\x70\x70\x7F\x7F\x07\x0F\x0F\x78\x0F\x78\x07".
  "\x0F\x0F\x0F\x70\x0F\x07\x70\x70\x70\x07\x70\x0F\x07\x07\x08\x00".
  "\x07\x0F\x07\x70\x70\x07\x0F\x70";    # help colors

use constant cpAppMonochrome =>
      "\x70\x07\x07\x0F\x70\x70\x70\x07\x0F\x07\x70\x70\x07\x70\x00".
  "\x07\x0F\x07\x70\x70\x07\x70\x00\x70\x70\x70\x07\x07\x70\x07\x00".
  "\x70\x70\x70\x07\x07\x70\x70\x70\x0F\x07\x07\x0F\x70\x0F\x70\x07".
  "\x0F\x0F\x07\x70\x07\x07\x70\x07\x07\x07\x70\x0F\x07\x07\x70\x00".
  "\x70\x70\x70\x07\x07\x70\x70\x70\x0F\x07\x07\x0F\x70\x0F\x70\x07".
  "\x0F\x0F\x07\x70\x07\x07\x70\x07\x07\x07\x70\x0F\x07\x07\x01\x00".
  "\x70\x70\x70\x07\x07\x70\x70\x70\x0F\x07\x07\x0F\x70\x0F\x70\x07".
  "\x0F\x0F\x07\x70\x07\x07\x70\x07\x07\x07\x70\x0F\x07\x07\x01\x00".
  "\x07\x0F\x07\x70\x70\x07\x0F\x70";    # help colors

# Standard application help contexts

# Note: range 0xFF00 - 0xFFFF of help contexts are reserved by Borland
use constant {
  hcNew          => 0xFF01,
  hcOpen         => 0xFF02,
  hcSave         => 0xFF03,
  hcSaveAs       => 0xFF04,
  hcSaveAll      => 0xFF05,
  hcChangeDir    => 0xFF06,
  hcDosShell     => 0xFF07,
  hcExit         => 0xFF08,
};

use constant {
  hcUndo         => 0xFF10,
  hcCut          => 0xFF11,
  hcCopy         => 0xFF12,
  hcPaste        => 0xFF13,
  hcClear        => 0xFF14,
};

use constant {
  hcTile         => 0xFF20,
  hcCascade      => 0xFF21,
  hcCloseAll     => 0xFF22,
  hcResize       => 0xFF23,
  hcZoom         => 0xFF24,
  hcNext         => 0xFF25,
  hcPrev         => 0xFF26,
  hcClose        => 0xFF27,
};

# TApplication palette entries

use constant {
  apColor      => 0,
  apBlackWhite => 1,
  apMonochrome => 2,
};

1