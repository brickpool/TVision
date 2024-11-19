package TV::App::Const;

use Exporter 'import';

our @EXPORT_OK = qw(
  CP_BACKGROUND
);

our %EXPORT_TAGS = (
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

use constant CP_BACKGROUND => "\x01";    # background palette

1
