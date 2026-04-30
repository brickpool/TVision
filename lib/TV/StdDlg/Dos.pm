package TV::StdDlg::Dos;
# ABSTRACT: Defines structures and functions for use similar to MS-DOS

use 5.010;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
  _dos_findfirst
  _dos_findnext
);

our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
);

use Class::Struct;
use TV::toolkit qw( signature );
use TV::toolkit::Types qw( :types );

use TV::StdDlg::FindFirstRec;

struct ffblk => [
  ff_reserved => '$',
  ff_fsize    => '$',
  ff_attrib   => '$',
  ff_ftime    => '$',
  ff_fdate    => '$',
  ff_name     => '$',
];

# The MSC find_t structure corresponds exactly to the ffblk structure
struct find_t => [
  reserved => '$',
  size     => '$',    # size of file
  attrib   => '$',    # attribute byte for matched file
  wr_time  => '$',    # time of last write to file
  wr_date  => '$',    # date of last write to file
  name     => '$',    # string name of matched file
];

sub _dos_findfirst {    # $int ($pathname, $attrib, $finfo)
  state $sig = signature(
    pos => [Str, PositiveOrZeroInt, ArrayLike],
  );
  my ( $pathname, $attrib, $finfo ) = $sig->( @_ );
  # The original findfirst sets errno on failure. We don't do this for now.
  my $r;
  if ( $r = FindFirstRec->allocate( $finfo, $attrib, $pathname ) ) {
    return $r->next() ? 0 : -1;
  }
  return -1
}

sub _dos_findnext {    # $int ($finfo)
  state $sig = signature(
    pos => [ArrayLike],
  );
  my ( $finfo ) = $sig->( @_ );
  my $r = FindFirstRec->get( $finfo );
  return 0
    if $r && $r->next();
  return -1;
}

1

__END__

=pod

=head1 NAME

TV::StdDlg::Dos - defines structures and functions for use similar to MS-DOS

=head1 DESCRIPTION

The code base was taken from the framework
I<"A modern port of Turbo Vision 2.0">.

=head1 SEE ALSO

I<dos.h>, I<dir.cpp>, 

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 CONTRIBUTORS

=over

=item magiblot <magiblot@hotmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1987, 1993 by Borland International

Copyright (c) 2019-2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution).

=cut
