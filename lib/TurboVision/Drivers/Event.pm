=pod

=head1 NAME

TEvent - event record definition

=head1 SYNOPSIS

  use 5.014;
  use TurboVision::Drivers::Event;
  use TurboVision::Drivers::Types qw( TEvent );
  use TurboVision::Drivers::Const qw( EV_MOUSE );

  my $ev = TEvent->new(what => EV_MOUSE, buttons => 2);
  ...
  if ( $ev->what & EV_MOUSE ) {
    say $ev->buttons;
    say $ev->where;
  }
  ...

=cut

package TurboVision::Drivers::Event;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use Function::Parameters qw(
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
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Devel::StrictMode;
use PerlX::Assert;
use Scalar::Util qw( refaddr );

use TurboVision::Const qw( :bool );
use TurboVision::Objects::Point;
use TurboVision::Objects::Types qw( TPoint );
use TurboVision::Drivers::Const qw( :evXXXX );
use TurboVision::Drivers::Types qw( TEvent );

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<TEvent> is a class defining each type of event used in Turbo Vision.

When a routine receives an event, it can look in the I<TEvent> fields to
determine what type of event occurred and use other information provided to
appropriately process that event.

For example, when the I<< TEvent->what >> field contains I<EV_MOUSE>, you can
check I<< TEvent->buttons >> to see which mouse button was pressed
(C<0>=none, C<1>=left, C<2>=right).

The I<< TEvent->double >> flag is set if two mouse clicks occurred within the
I<$double_delay> time interval.

Lastly, for each mouse event, I<< TEvent->where >> contains the coordinates of
the mouse.

When the event record contains broadcast I<EV_MESSAGE> events, several variant
fields are provided for passing additional information with the message. 

I<< TEvent->info_ptr >> can be used, for instance, to pass a reference to a
record or another object.

=cut

=head2 Class

public class C<< TEvent >>

=cut

package TurboVision::Drivers::Event {

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Attributes

=over

=item public C<< Int what >>

Event type.

=cut

  has 'what' => (
    is        => 'rw',
    isa       => Int,
    required  => 1,
    default   => EV_NOTHING,
  );

=over

=item public C<< Int buttons >>

Mouse buttons.

=cut

  has 'buttons' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
  );

=item public C<< Bool double >>

Double click stat.

=cut

  has 'double' => (
    is      => 'rw',
    isa     => Bool,
    default => _FALSE,
  );

=item public C<< TPoint where >>

Mouse position.

=cut

  has 'where' => (
    is      => 'rw',
    isa     => TPoint,
    default => sub { TPoint->new(x => 0, y => 0) },
  );

=item public C<< Int key_code >>

Full key code.

=cut

  has 'key_code' => (
    is      => 'rw',
    isa     => Int,
    default => 0x0000,
  );

=item public C<< Str text >>

May contain whatever was read from the terminal: usually a UTF-8 sequence, but
possibly any kind of raw data.

=cut

  has 'text' => (
    is        => 'rw',
    isa       => Str,
    init_arg  => undef,
    default   => '',
  );
  sub get_text { goto &text }

=item public C<< Int command >>

Message command.

=cut

  has 'command' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
  );

=item public C<< Ref|Int|Undef info >>

Message info.

=cut

  has 'info' => (
    is        => 'rw',
    isa       => Ref|Int|Undef,
    init_arg  => undef,
    default   => undef,
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => TEvent;

=begin comment

=head2 Constructors

=over

=item private C<< BUILD($args) >>

If any of the following environment variables are true at compile time, the
I<what> attribute is checked and, if it fails, an exception is thrown.

  PERL_STRICT
  AUTHOR_TESTING
  EXTENDED_TESTING
  RELEASE_TESTING

See also: I<PerlX::Assert>

=end comment

=cut

  method BUILD($args) {
    return
        if not STRICT;

    my $what = $self->what();
    SWITCH: for ( delete $args->{what} ) {
      $_ == EV_NOTHING and do {
        last;
      };

      confess qq{Missing argument for 'what => $what'}
        if not %{ $args };

      $_ & EV_MOUSE and do {
        LOOP: for ( keys %{ $args } ) {
             /^buttons$/
          || /^double$/
          || /^where$/ and do {
            next LOOP;
          };
          confess qq{Invalid argument '$_' for 'what => $what'}
        }
        last;
      };

      $_ & EV_KEYBOARD and do {
        LOOP: for ( keys %{ $args } ) {
          /^key_code$/ and do {
            next LOOP;
          };
          /^char_code$/ and do {
            $self->char_code( $args->{$_} );
            next LOOP;
          };
          /^scan_code$/ and do {
            $self->scan_code( $args->{$_} );
            next LOOP;
          };
          DEFAULT: {
            confess qq{Invalid argument '$_' for 'what => $what'}
          }
        }
        last;
      };

      $_ & EV_MESSAGE and do {
        LOOP: for ( keys %{ $args } ) {
          /^command$/ and do {
            next LOOP;
          };
          /^info_ptr$/ and do {
            $self->info_ptr( $args->{$_} );
            next LOOP;
          };
          /^info_long$/ and do {
            $self->info_long( $args->{$_} );
            next LOOP;
          };
          /^info_word$/ and do {
            $self->info_word( $args->{$_} );
            next LOOP;
          };
          /^info_int$/ and do {
            $self->info_int( $args->{$_} );
            next LOOP;
          };
          /^info_byte$/ and do {
            $self->info_byte( $args->{$_} );
            next LOOP;
          };
          /^info_char$/ and do {
            $self->info_char( $args->{$_} );
            next LOOP;
          };
          DEFAULT: {
            confess qq{Invalid argument '$_' for 'what => $what'}
          }
        }
        last;
      };

      DEFAULT: {
        confess qq{Invalid value '$what' for argument 'what'}
      }
    };

    return;
  }
  
=back

=cut

  # ------------------------------------------------------------------------
  # TEvent -----------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

Stream interface routines

=over

=item public C<< Ref|Undef info_ptr(Ref $value=) >>

Message Reference.

=cut

  method info_ptr(@) {
		my ($value) = @_;

    goto SET if @_;
    GET: {
      return $self->info() || undef;
    }
    SET: {
			assert { @_ == 1 && ( !defined($value) || is_Ref($value) ) };
      $self->info( $value );
      return $value;
    }
  };

=item public C<< Int info_long(Int $value=) >>

Message I<longint> (signed integer 32-bit).

=cut

  method info_long(@) {
		my ($value) = @_;

    goto SET if @_;
    GET: {
      my $v = $self->info();
      $v = 0 if not is_Int $v;
      $v = unpack('V!', pack('V!', $v));
      return $v;
    }
    SET: {
			assert { @_ == 1 && is_Int $value };
      my $v = unpack('V!', pack('V!', $value));
      $self->info( $v );
      return $v;
    }
  }

=item public C<< Int info_word(Int $value=) >>

Message I<word> (unsigned integer 16-bit).

=cut

  method info_word(@) {
		my ($value) = @_;

    goto SET if @_;
    GET: {
      my $v = $self->info();
      $v = 0 if not is_Int $v;
      $v = unpack('v', pack('v', $v));
      return $v;
    }
    SET: {
			assert { @_ == 1 && is_Int $value };
      my $v = unpack('v', pack('v', $value));
      $self->info( $v );
      return $v;
    }
  }

=item public C<< Int info_int(Int $value=) >>

Message I<integer> (signed integer 16-bit).

=cut

  method info_int(@) {
		my ($value) = @_;

    goto SET if @_;
    GET: {
      my $v = $self->info();
      $v = 0 if not is_Int $v;
      $v = unpack('v!', pack('v!', $v));
      return $v;
    }
    SET: {
			assert { @_ == 1 && is_Int $value };
      my $v = unpack('v!', pack('v!', $value));
      $self->info( $v );
      return $v;
    }
  }

=item public C<< Int info_byte(Int $value=) >>

Message I<byte> (unsigned integer 8-bit).

=cut

  method info_byte(@) {
		my ($value) = @_;

    goto SET if @_;
    GET: {
      my $v = $self->info();
      $v = 0 if not is_Int $v;
      $v &= 0xff;
      return $v;
    }
    SET: {
			assert { @_ == 1 && is_Int $value };
      my $v = $value & 0xff;
      $self->info( $v );
      return $v;
    }
  }

=item public C<< Str info_char(Str $value=) >>

Message Perl string, which represents 1 character.

=cut

  method info_char(@) {
		my ($value) = @_;

    goto SET if @_;
    GET: {
      my $v = $self->info();
      $v = 0 if not is_Int $v;
      $v &= 0x10ffff;                                   # max valid code point
      $v = pack('W', $v);
      return $v;
    }
    SET: {
			assert { @_ == 1 && is_Str $value };
      my $v = unpack('W', $value);
      $self->info( $v );
      $v = pack('W', $v);
      return $v;
    }
  }

=item public C<< Int char_code(Int $value=) >>

Char code.

=cut

  method char_code(@) {
		my ($value) = @_;

    goto SET if @_;
    GET: {
      my $v = $self->key_code();
      $v &= 0x00ff;
      return $v;
    }
    SET: {
			assert { @_ == 1 && is_Int $value };
      my $v = $self->key_code();
      $v &= 0xff00;
      $v |= $value & 0x00ff;
      $v &= 0xffff;
      $self->key_code( $v );
      return $v;
    }
  }

=item public C<< Int scan_code(Int $value=) >>

Scan code.

=cut

  method scan_code(@) {
		my ($value) = @_;

    goto SET if @_;
    GET: {
      my $v = $self->key_code();
      $v >>= 8;
      $v &= 0x00ff;
      return $v;
    }
    SET: {
			assert { @_ == 1 && is_Int $value };
      my $v = $self->key_code();
      $v &= 0x00ff;
      $v |= $value << 8;
      $v &= 0xffff;
      $self->key_code( $v );
      return $v;
    }
  }

=item private C<< Str _stringify() >>

Overload stringify so we can write code like C<< print $ev >>.

=cut

	method _stringify(@) {
    my $format = <<'END_STRING';
what : 0x%04x;
key_code
  scan_code : 0x%02x;
  char_code : 0x%02x;
text : %s
buttons : %d;
double : %d;
where
  x : %d;
  y : %d;
info_ptr 0x%x;
info_long %d;
info_word %d;
info_int %d;
info_byte %d;
info_char %s;
END_STRING
    return sprintf($format, 
      $self->what,
      $self->scan_code,
      $self->char_code,
      $self->text,
      $self->buttons,
      $self->double,
      $self->where->x,
      $self->where->y,
      refaddr($self->info_ptr) // 0,
      $self->info_long,
      $self->info_word,
      $self->info_int,
      $self->info_byte,
      $self->info_char
    );
  }
  use overload '""' => \&_stringify, fallback => 1;

=back

=head2 Inheritance

Methods inherited from class C<Object>

  new, BUILDARGS, does, DOES, dump, DESTROY

=cut
  
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Turbo Vision library.

 Interface Copyright (c) 1992 Borland International

 The library files are licensed under modified LGPL.

 The creation of subclasses of this LGPL-licensed class is considered to be
 using an interface of a library, in analogy to a function call of a library.
 It is not considered a modification of the original class. Therefore,
 subclasses created in this way are not subject to the obligations that an LGPL
 imposes on licensees.

 POD sections by Ed Mitchell are licensed under modified CC BY-NC-ND.

=head1 AUTHORS
 
=over

=item *

2021-2022 by J. Schneider L<https://github.com/brickpool/>

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

=head1 CONTRIBUTOR

Output via I<_stringify>, and parts of I<char_code> and I<scan_code>.

=over

=item *

2021 by Oleg Denisenko L<https://github.com/10der/>

=back

=head1 SEE ALSO

L<drivers.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/drivers.pas>
