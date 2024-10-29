=pod

=head1 DESCRIPTION

The calculation of C<MAX_COLLECTION_SIZE> uses the size of a pointer to 
determine the maximum number of elements in the collection. 

=cut

package TV::Objects::Const;

use Exporter 'import';

our @EXPORT_OK = qw(
  CC_NOT_FOUND
  MAX_COLLECTION_SIZE
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

use constant {
  CC_NOT_FOUND => -1
};

use constant {
  MAX_COLLECTION_SIZE => int( ( ( 2**32 - 1 ) - 16 ) / length( pack('P', 0) ) ),
};

1
