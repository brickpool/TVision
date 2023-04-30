=pod

=head1 NAME

TurboVision::Objects - Import I<TurboVision::Objects::X> packages into one
package

=head1 SYNOPSIS

  use TurboVision::Objects;

  # Use constant or define any objects
  ...

=cut

package TurboVision::Objects;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Carp qw( confess );

use TurboVision::Objects::Const;
use TurboVision::Objects::Common;
use TurboVision::Objects::Types;

use TurboVision::Objects::Point;
use TurboVision::Objects::Rect;
use TurboVision::Objects::StreamRec;
use TurboVision::Objects::Stream;
use TurboVision::Objects::DosStream;
use TurboVision::Objects::BufStream;
use TurboVision::Objects::MemoryStream;
use TurboVision::Objects::Collection;
use TurboVision::Objects::SortedCollection;
use TurboVision::Objects::StringCollection;
use TurboVision::Objects::ResourceCollection;
use TurboVision::Objects::ResourceFile;
use TurboVision::Objects::StringList;
use TurboVision::Objects::StrListMaker;

use Import::Into;

=head1 DESCRIPTION

I<TurboVision::Objects> is a simple wrapper for all constants, types, routines
and classes of the I<TurboVision::Objects::X> module hierarchy.

=head2 Modules

The following is the equivalent notation that is imported here:

  use TurboVision::Objects::Const qw( :all !:private );
  use TurboVision::Objects::Common qw( :all );
  use TurboVision::Objects::Types qw( :all );
  
  use TurboVision::Objects::Point;
  use TurboVision::Objects::Rect;
  use TurboVision::Objects::StreamRec;
  use TurboVision::Objects::Stream;
  use TurboVision::Objects::DosStream;
  use TurboVision::Objects::BufStream;
  use TurboVision::Objects::MemoryStream;
  use TurboVision::Objects::Collection qw( :all );
  use TurboVision::Objects::SortedCollection qw( :all );
  use TurboVision::Objects::StringCollection;
  use TurboVision::Objects::ResourceCollection;
  use TurboVision::Objects::ResourceFile;
  use TurboVision::Objects::StringList qw( :all );
  use TurboVision::Objects::StrListMaker qw( :all );

=cut

sub import {
  my ($class, $type) = @_;
  if (defined $type) {
    confess sprintf('"%s" is not exported by the %s module', $type, $class);
  }

  my $target = caller;
  TurboVision::Objects::Const->import::into($target, qw( :all ));
  TurboVision::Objects::Common->import::into($target, qw( :all ));
  TurboVision::Objects::Types->import::into($target, qw( :all ));
  TurboVision::Objects::Collection->import::into($target, qw( :all ));
  TurboVision::Objects::SortedCollection->import::into($target, qw( :all ));
  TurboVision::Objects::StringList->import::into($target, qw( :all ));
  TurboVision::Objects::StrListMaker->import::into($target, qw( :all ));
}

sub unimport {
  my $caller = caller;
  TurboVision::Objects::Const->unimport::out_of($caller);
  TurboVision::Objects::Common->unimport::out_of($caller);
  TurboVision::Objects::Types->unimport::out_of($caller);
  TurboVision::Objects::Collection->unimport::out_of($caller);
  TurboVision::Objects::SortedCollection->unimport::out_of($caller);
  TurboVision::Objects::StringList->unimport::out_of($caller);
  TurboVision::Objects::StrListMaker->unimport::out_of($caller);
}

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Turbo Vision library.

 Interface Copyright (c) 1992 Borland International

 The library files are licensed under modified LPGL.

 The creation of subclasses of this LGPL-licensed class is considered to be
 using an interface of a library, in analogy to a function call of a library.
 It is not considered a modification of the original class. Therefore,
 subclasses created in this way are not subject to the obligations that an LGPL
 imposes on licensees.

=head1 AUTHORS
 
=over

=item *

2021-2022 by J. Schneider L<https://github.com/brickpool/>

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

L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
