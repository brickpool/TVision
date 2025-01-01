package TV::Objects::Const;

use Exporter 'import';

our @EXPORT_OK = qw(
  ccNotFound
  maxCollectionSize
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

use Config;
use TV::Const qw( UINT_MAX );

use constant {
  ccNotFound => -1
};

# The calculation of 'maxCollectionSize' uses the size of a pointer to 
# determine the maximum number of elements in the collection. 
use constant {
  maxCollectionSize => int( ( UINT_MAX - 16 ) / $Config{ptrsize} ),
};

1
