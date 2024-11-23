=pod

=head1 DESCRIPTION

Miscellaneous system-wide configuration parameters.

=cut

package TV::Const;

use Exporter 'import';

our @EXPORT_OK = qw(
  INT_MAX
  UINT_MAX

  maxFindStrLen
  maxReplaceStrLen
);

use constant {
  INT_MAX  => ~0 >> 1,
  UINT_MAX => ~0,
};

use constant {
  maxFindStrLen     => 80,
  maxReplaceStrLen  => 80,
};

1
