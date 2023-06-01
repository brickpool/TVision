=pod

=head1 NAME

TurboVision::Objects::Const - Constants used by I<Objects>

=head1 SYNOPSIS

  use TurboVision::Objects::Const qw(
    MAX_COLLECTION_SIZE
    :stXXXX
  );
  ...

=cut

package TurboVision::Objects::Const;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:fpc';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Config;
use Exporter qw( import );

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all
    MAX_COLLECTION_SIZE
  
    :coXXXX
      CO_INDEX_ERROR
      CO_OVERFLOW
  
    :stXXXX
      ST_OK
      ST_ERROR
      ST_INIT_ERROR
      ST_READ_ERROR
      ST_WRITE_ERROR
      ST_GET_ERROR
      ST_PUT_ERROR
      ST_CREATE
      ST_OPEN_READ
      ST_OPEN_WRITE
      ST_OPEN

=cut

our @EXPORT_OK = qw(
  MAX_COLLECTION_SIZE
);

our %EXPORT_TAGS = (

  coXXXX => [qw(
    CO_INDEX_ERROR
    CO_OVERFLOW
  )],

  stXXXX => [qw(
    ST_OK
    ST_ERROR
    ST_INIT_ERROR
    ST_READ_ERROR
    ST_WRITE_ERROR
    ST_GET_ERROR
    ST_PUT_ERROR
    ST_CREATE
    ST_OPEN_READ
    ST_OPEN_WRITE
    ST_OPEN
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

=head1 DESCRIPTION

tbd

=cut

# ------------------------------------------------------------------------
# Constants --------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 CONSTANTS

=head2 Constants provided by I<Objects>

=over

=item I<MAX_COLLECTION_SIZE>

  constant MAX_COLLECTION_SIZE = < Int >;

I<MAX_COLLECTION_SIZE> determines the maximum number of elements a
collection can contain.

=cut

  use constant MAX_COLLECTION_SIZE => (1 << $Config{u16size} * 8) - 1;

=back

=cut

=head2 Collection error codes (I<:coXXXX>)

=over

=item I<CO_INDEX_ERROR>

  constant CO_INDEX_ERROR = < Int >;

Index out of range

=cut

  use constant CO_INDEX_ERROR => -1;

=item I<CO_OVERFLOW>

  constant CO_OVERFLOW = < Int >;

Overflow

=cut
 
  use constant CO_OVERFLOW    => -2;

=back

=cut

=head2 Stream error state masks (I<:stXXXX>)

=over

=item I<ST_OK>

  constant ST_OK = < Int >;

No stream error

=cut

  use constant ST_OK         =>  0;                                 

=item I<ST_ERROR>

  constant ST_ERROR = < Int >;

Access error

=cut

  use constant ST_ERROR       => -1;

=item I<ST_INIT_ERROR>

  constant ST_INIT_ERROR = < Int >;

Initialize error

=cut

  use constant ST_INIT_ERROR  => -2;

=item I<ST_READ_ERROR>

  constant ST_READ_ERROR = < Int >;

Stream read error

=cut

  use constant ST_READ_ERROR  => -3;

=item I<ST_WRITE_ERROR>

  constant ST_WRITE_ERROR = < Int >;

Stream write error

=cut

  use constant ST_WRITE_ERROR => -4;

=item I<ST_GET_ERROR>

  constant ST_GET_ERROR = < Int >;

Get object error

=cut

  use constant ST_GET_ERROR   => -5;

=item I<ST_PUT_ERROR>

  constant ST_PUT_ERROR = < Int >;

Put object error

=cut

  use constant ST_PUT_ERROR   => -6;

=back

=cut

=head2 Stream access mode constants (I<:stXXXX>)

=over

=item I<ST_CREATE>

  constant ST_CREATE = < Int >;

Create new file

=cut

  use constant ST_CREATE      => 0x3C00;

=item I<ST_OPEN_READ>

  constant ST_OPEN_READ = < Int >;

Read access only

=cut

  use constant ST_OPEN_READ   => 0x3D00;

=item I<ST_OPEN_WRITE>

  constant ST_OPEN_WRITE = < Int >;

Write access only

=cut

  use constant ST_OPEN_WRITE  => 0x3D01;

=item I<ST_OPEN>

  constant ST_OPEN = < Int >;

Read/write access

=cut

  use constant ST_OPEN        => 0x3D02;

=back

=cut

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Free Pascal run time library.
 Copyright (c) 1999-2000 by the Free Pascal development team.

 Interface Copyright (c) 1992 Borland International

 The run-time files are licensed under modified LGPL.

 The creation of subclasses of this LGPL-licensed class is considered to be
 using an interface of a library, in analogy to a function call of a library.
 It is not considered a modification of the original class. Therefore,
 subclasses created in this way are not subject to the obligations that an LGPL
 imposes on licensees.

=head1 AUTHORS

=over

=item *

2021-2023 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 DISCLAIMER OF WARRANTIES

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

I<Objects>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
