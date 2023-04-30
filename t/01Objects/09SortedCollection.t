use 5.014;
use warnings;
use Test::More;

BEGIN {
  use_ok 'TurboVision::Objects::SortedCollection';
}

package TNumCollection {
  use Moose;
  use MooseX::Types::Moose qw( is_Ref );
  use TurboVision::Objects::SortedCollection;
  use TurboVision::Objects::Types qw( TSortedCollection );

  extends TSortedCollection->class;
  
  around 'compare' => sub {
    my (undef, undef, $key1, $key2) = @_;
    return 0
        if @_ != 4
        || !is_Ref $key1
        || !is_Ref $key2;
    return $$key1 <=> $$key2;
  };

  no Moose;
}

my $col = TNumCollection->init();
isa_ok(
  $col,
  'TNumCollection'
);

$col->insert(\2);
$col->insert(\4);
$col->insert(\3);
$col->insert(\5);
$col->insert(\6);
$col->insert(\1);

my $sum = '';
$col->for_each( sub { $sum .= $$_ } );

like(
  $sum,
  qr/^123456$/,
  'TSortedCollection->index_of & insert & key_of & search'
);

done_testing;
