=pod

=head1 DESCRIPTION

Miscellaneous system-wide configuration parameters.

=cut

package TV::Const;

use Exporter 'import';

our @EXPORT_OK = qw(
  INT_MAX
  UINT_MAX

  EVENT_Q_SIZE
  MAX_COLLECTION_SIZE

  MAX_VIEW_WIDTH

  MAX_FIND_STR_LEN
  MAX_REPLACE_STR_LEN
);

use Config;

use constant {
  INT_MAX  => ~0 >> 1,
  UINT_MAX => ~0,
};

# The calculation of C<MAX_COLLECTION_SIZE> uses the size of a pointer to 
# determine the maximum number of elements in the collection. 
use constant {
  EVENT_Q_SIZE        => 16,
  MAX_COLLECTION_SIZE => int( ( UINT_MAX - 16 ) / $Config{ptrsize} ),
};

use constant {
  MAX_VIEW_WIDTH      => 132,
};

use constant {
  MAX_FIND_STR_LEN    => 80,
  MAX_REPLACE_STR_LEN => 80,
};

1
