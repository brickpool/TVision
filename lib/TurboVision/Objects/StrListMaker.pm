=pod

=head1 NAME

TStrListMaker - Simple class for creating string lists with I<TStringList>

=head1 SYNOPSIS

  use TurboVision::Objects;
  ...
    use constant S_INFORMATION  => 100;
    use constant S_WARNING      => 101;
    use constant S_ERROR        => 102;
    use constant S_LOADING_FILE => 200;
    use constant S_SAVING_FILE  => 201;
  
    my ($res_file, $s);
    
    TStreamRec->register_type(RStrListMaker);
    $res_file = TResourceFile->init(
      TBufStream->init('myapp.res', ST_CREATE, l024)
    );
    $s = TStrListMaker->init(16384, 256);
    
    $s->put(S_INFORMATION, 'Information');
    $s->put(S_WARNING, 'Warning');
    $s->put(S_ERROR, 'Error');
    $s->put(S_LOADING_FILE, 'Loading file %s.');
    $s->put(S_SAVING_FILE, 'Saving file %s,');
    
    $res_file->put($s, 'Strings');
  }

=cut

package TurboVision::Objects::StrListMaker;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use Function::Parameters {
  factory => {
    defaults    => 'classmethod_strict',
    shift       => '$class',
    name        => 'required',
  },
},
qw(
  method
);

use Moose;
use MooseX::Types::Moose qw( :all );
use MooseX::HasDefaults::RO;
use namespace::autoclean;

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:fpc';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Data::Alias qw( alias );
use MooseX::Types::Common::String qw( is_SimpleStr );

use TurboVision::Objects::Common qw(
  byte
  longint
  word
);
use TurboVision::Objects::Const qw( ST_OK );
use TurboVision::Objects::Object;
use TurboVision::Objects::Stream;
use TurboVision::Objects::StreamRec;
use TurboVision::Objects::Types qw(
  TObject
  TStream
  TStreamRec
  TStrIndex
  TStrListMaker
);

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

use Moose::Exporter;
Moose::Exporter->setup_import_methods(
  as_is => [ 'RStrListMaker' ],
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<TStrListMaker> creates the string resources to be subsequently access by
I<TStringList>.

=head2 Class

public class I<< TStrListMaker >>

Turbo Vision Hierarchy

  TObject
    TStringList
    TStrListMaker

=cut

package TurboVision::Objects::StrListMaker {

  extends TObject->class;

  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Constants

=over

=item public constant C<< Object RStrListMaker >>

Defining a registration record constant for I<TStrListMaker>.

I<TStrListMaker> is registered with
I<< TStreamRec->register_type(RStrListMaker) >>.

=cut

  use constant RStrListMaker => TStreamRec->new(
    obj_type  => 52,
    vmt_link  => __PACKAGE__,
    store     => 'store',
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------

=begin comment

=item private C<< HashRef _cur >>

Holds the current hash of I<_index>.

=end comment

=cut

  has '_cur' => (
    is        => 'rw',
    isa       => HashRef,
    default   => sub {
      return {
        key     => 0,
        count   => 0,
        offset  => 0,
      };
    },
  );

=begin comment

=item private C<< ArrayRef[HashRef] _index >>

As strings are added to the string list, a string index is built.

The HashRef is a equivalent for I<TStringList> which has the following form:

  $record = {
    key     => $key,
    count   => $count,
    offset  => $offset,
  };

The hash entries I<$key>, I<$count> and I<$offset> are all of type I<Int>.

=end comment

=cut

  has '_index' => (
    is        => 'rw',
    isa       => TStrIndex,
    default   => sub { [] },
  );

=begin comment

=item private C<< Int _index_pos >>

Index position.

=end comment

=cut

  has '_index_pos' => (
    is        => 'rw',
    isa       => Int,
    default   => 0,
  );

=begin comment

=item private C<< Int _index_size >>

Hold the index size.

=end comment

=cut

  has '_index_size' => (
    is        => 'rw',
    isa       => Int,
    required  => 1,
  );

=begin comment

=item private C<< Int _str_pos >>

String position.

=end comment

=cut

  has '_str_pos' => (
    is        => 'rw',
    isa       => Int,
    default   => 0,
  );

=begin comment

=item private C<< Int _str_size >>

Hold string size.

=end comment

=cut

  has '_str_size' => (
    is        => 'rw',
    isa       => Int,
    required  => 1,
  );

=begin comment

=item private C<< Str _strings >>

Hold all strings as a packed string of bytes.

=end comment

=cut

  has '_strings' => (
    is        => 'rw',
    isa       => Str,
    required  => 1,
  );
  
  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => TStrListMaker;

=head2 Constructors

=over

=item public C<< TStrListMaker->init(Int $a_str_size, Int $a_index_size) >>
 
The constructor I<init> reserves a string buffer having I<$a_str_size> bytes and
index of I<$a_index_size> elements.

All of the strings that you add to the list are added into the string buffer, so
I<$a_str_size> sould be large enough to hold all the strings.

=cut

  factory init(Int $a_str_size, Int $a_index_size) {
    return $class->new(
      _str_size   => $a_str_size,
      _index_size => $a_index_size,
      _strings    => "\0" x $a_str_size,
    );
  };

=back

=cut

  # ------------------------------------------------------------------------
  # TStrListMaker ------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item public C<< put(Int $key, SimpleStr $s) >>

Use I<put> to add each string into the string list, where I<$key> is the index
value to assign to the string, and I<$s> is the string value.

The I<TStrListMaker> appears to have no error checking so make sure that you do
not add more elements than were specified by I<a_index_size> and which will fit
into the string buffer.
 
=cut

  method put(Int $key, $) {
    alias my $s       = $_[-1];                           # refer to parameter
    alias my $cur     = $self->{_cur};                    # refer to attributes
    alias my $strings = $self->{_strings};
    alias my $str_pos = $self->{_str_pos};
    confess 'Invalid argument $s'
      if not is_SimpleStr $s;

    if ( $cur->{count} == 16 || $key != $cur->{key}+$cur->{count} ) {
      $self->_close_current();                            # Close current
    }
    if ( $cur->{count} == 0 ) {
      $cur->{key}    = $key;                              # Set key
      $cur->{offset} = $str_pos;                          # Set offset
    }
    $cur->{count}++;                                      # Inc count

    # Copy(length($s), $strings[$str_pos], 1, U8);
    my $len = length $s;
    my $n = byte( $len )->pack;
    substr($strings, $str_pos, byte->size, $n);           # Copy string length
    $str_pos += byte->size;                               # Adjust position

    # Copy($s, $strings[$str_pos], length($s), PV);
    if ( $len ) {
      substr($strings, $str_pos, $len, $s);               # Copy string data
      $str_pos += $len;                                   # Adjust position
    }

    return;
  }

=item public C<< store(TStream $s) >>

Writes the string list to stream I<$s>.

=cut

  method store(TStream $s) {
    $self->_close_current();                              # Close all current

    # Write position
    my $str_pos = word( $self->_str_pos )->cast() // 0;
    $s->write(
      word( $str_pos )->pack(),
      word->size
    );
    # Write string data
    alias my $strings = $self->{_strings};
    $s->write($strings, $str_pos);

    # Write index position
    my $index_pos = longint( $self->_index_pos )->cast() // 0;
    $s->write(
      longint( $index_pos )->pack(),
      longint->size
    );

    # Write indexes
    WRITE:
    for my $i (0..$index_pos-1) {
      last WRITE if $s->status != ST_OK;
      alias my $record = $self->_index->[$i];
      my $key     = word( $record->{key} )->pack;
      my $count   = word( $record->{count} )->pack;
      my $offset  = word( $record->{offset} )->pack;
      $s->write($key,    word->size);
      $s->write($count,  word->size);
      $s->write($offset, word->size);
    }

    return;
  }

=begin comment

=item private C<< _close_current() >>

I<TStrListMaker> private method.

=end comment

=cut

  method _close_current() {
    alias my $cur       = $self->{_cur};                  # refer to attributes
    alias my $index     = $self->{_index};
    alias my $index_pos = $self->{_index_pos};

    if ( $cur->{count} != 0 ) {
      $index->[$index_pos] = { %$cur };                   # Hold index position
      $index_pos++;                                       # Next index
      $cur->{count} = 0;                                  # Adjust count
    }
    return;
  }

=back

=head2 Inheritance

Methods inherited from class L<Moose::Object>

  new, BUILDARGS, does, DOES, dump, DESTROY

=cut

}

__PACKAGE__->meta->make_immutable;

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

 POD sections by Ed Mitchell are licensed under modified CC BY-NC-ND.

=head1 AUTHORS

=over

=item *

1999-2000 by Florian Klaempfl E<lt>fnklaemp@cip.ft.uni-erlangen.deE<gt>

=item *

1999-2000 by Frank ZAGO E<lt>zago@ecoledoc.ipc.frE<gt>

=item *

1999-2000 by MH Spiegel

=item *

1996, 1999-2000 by Leon de Boer E<lt>ldeboer@ibm.netE<gt>

=item *

1992 by Ed Mitchell (Turbo Pascal Reference electronic freeware book)

=back

=head1 DISCLAIMER OF WARRANTIES

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.

=head1 MAINTAINER

=over

=item *

2021 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

I<TObject>, I<TStringList>,
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
