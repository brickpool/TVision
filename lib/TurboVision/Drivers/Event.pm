=pod

=head1 NAME

TEvent - A record definition for all types of events.

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

use constant::boolean;
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

use Carp;
use Devel::StrictMode;
use Scalar::Util qw( refaddr );

use TurboVision::Drivers::Const qw( :evXXXX );
use TurboVision::Drivers::Types qw( TEvent );
use TurboVision::Objects::Point;
use TurboVision::Objects::Types qw( TPoint );

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<TEvent> is a class defining each type of event used in Turbo Vision.

When a routine receives an event, it can look in the I<TEvent> fields to
determine what type of event occurred and use other information provided to
appropriately process that event.

For example, when the L</what> field contains I<EV_MOUSE>, you can check
L</buttons> to see which mouse button was pressed (C<0>=none, C<1>=left,
C<2>=right).

The L</double> flag is set if two mouse clicks occurred within the
I<$double_delay> time interval.

Lastly, for each mouse event, L</where> contains the coordinates of the mouse.

When the event record contains broadcast I<EV_MESSAGE> events, several variant
fields are provided for passing additional information with the message. 

L</info_ptr> can be used, for instance, to pass a reference to a array, hash or
another object.

=cut

=head2 Class

public class I<< TEvent >>

Turbo Vision Hierarchy

  Moose::Object
    TEvent

=head2 Declaration

The I<TEvent> type, as described in I<JSON>

  {
    "TEvent": {
      "what": {
        "type": {
          "case": [{
              "EV_NOTHING": null
            }, {
              "EV_MOUSE": {
                "buttons": {
                  "type": "Int"
                },
                "double": {
                  "type": "Bool"
                },
                "where": {
                  "type": "TPoint"
                }
              }
            }, {
              "EV_KEY_DOWN": [{
                  "id": 0,
                  "KeyCode": {
                    "type": "Int"
                  }
                }, {
                  "id": 1,
                  "CharCode": {
                    "type": "Int"
                  },
                  "ScanCode": {
                    "type": "Int"
                  }
                },
              ]
            }, {
              "EV_MESSAGE": {
                "command": {
                  "type": {
                    "info": [{
                        "id": 0,
                        "info_ptr": {
                          "type": ["Ref", null]
                        }
                      }, {
                        "id": 1,
                        "info_long": {
                          "type": "Int"
                        }
                      }, {
                        "id": 2,
                        "info_word": {
                          "type": "Int"
                        }
                      }, {
                        "id": 3,
                        "info_int": {
                          "type": "Int"
                        }
                      }, {
                        "id": 4,
                        "info_byte": {
                          "type": "Int"
                        }
                      }, {
                        "id": 5,
                        "info_char": {
                          "type": "Int"
                        }
                      }
                    ]
                  }
                }
              }
            }
          ]
        }
      }
    }
  }

=cut

package TurboVision::Drivers::Event {

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Attributes

=over

=item I<buttons>

  has buttons ( is => rw, type => Int ) = 0;

Mouse buttons.

=cut

  has 'buttons' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
  );

=item I<command>

  has command ( is => rw, type => Int ) = 0;

Message command.

=cut

  has 'command' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
  );

=item I<double>

  has double ( is => rw, type => Bool ) = !! 0;

Double click stat.

=cut

  has 'double' => (
    is      => 'rw',
    isa     => Bool,
    default => FALSE,
  );

=item I<key_code>

  has key_code ( is => rw, type => Int ) = 0x0000;

Full key code.

=cut

  has 'key_code' => (
    is      => 'rw',
    isa     => Int,
    default => 0x0000,
  );

=item I<info>

  field info ( is => rw, type => Ref|Int|Undef );

Message info.

=cut

  has 'info' => (
    is        => 'rw',
    isa       => Ref|Int|Undef,
    init_arg  => undef,
    default   => undef,
  );

=item I<text>

  field text ( is => rw, type => Str ) = '';

May contain whatever was read from the terminal: usually a UTF-8 sequence, but
possibly any kind of raw data.

=cut

  has 'text' => (
    is        => 'rw',
    isa       => Str,
    init_arg  => undef,
    default   => '',
  );

=item I<what>

  has what ( is => rw, type => Int ) = EV_NOTHING;

Event type.

=cut

  has 'what' => (
    is        => 'rw',
    isa       => Int,
    default   => EV_NOTHING,
  );

=item I<where>

  has where ( is => rw, type => TPoint ) = TPoint->new();

Mouse position.

=cut

  has 'where' => (
    is      => 'rw',
    isa     => TPoint,
    default => sub { TPoint->new() },
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => __PACKAGE__;

=begin comment

=head2 Constructors

=over

=item I<BUILD>

  method BUILD(HashRef $args)

If any of the following environment variables are true at compile time, the
I<what> attribute is checked and, if it fails, an exception is thrown.

  PERL_STRICT
  AUTHOR_TESTING
  EXTENDED_TESTING
  RELEASE_TESTING

B<See also>: L<Devel::StrictMode>

=end comment

=cut

  method BUILD(HashRef $args) {
    return
        if not STRICT;

    my $what = $self->what();
    SWITCH: for ( delete($args->{what}) // 0 ) {
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

=item I<char_code>

  multi method char_code() : Int
  multi method char_code(Int $value) : Int

Char code.

=cut

  method char_code(Maybe[Int] $value=) {
    goto SET if @_;
    GET: {
      my $v = $self->key_code();
      $v &= 0x00ff;
      return $v;
    }
    SET: {
      confess unless defined $value;
      my $v = $self->key_code();
      $v &= 0xff00;
      $v |= $value & 0x00ff;
      $v &= 0xffff;
      $self->key_code( $v );
      return $v;
    }
  }

=item I<info_byte>

  multi method info_byte() : Int
  multi method info_byte(Int $value) : Int

Message I<byte> (unsigned integer 8-bit).

=cut

  method info_byte(Maybe[Int] $value=) {
    goto SET if @_;
    GET: {
      my $v = $self->info();
      $v = 0 if not is_Int $v;
      $v &= 0xff;
      return $v;
    }
    SET: {
      confess unless defined $value;
      my $v = $value & 0xff;
      $self->info( $v );
      return $v;
    }
  }

=item I<info_char>

  multi method info_char() : Str
  multi method info_char(Str $value) : Str

Message Perl string, which represents 1 character.

=cut

  method info_char(Maybe[Str] $value=) {
    goto SET if @_;
    GET: {
      my $v = $self->info();
      $v = 0 if not is_Int $v;
      $v &= 0x10ffff;                                   # max valid code point
      $v = pack('W', $v);
      return $v;
    }
    SET: {
      confess unless defined $value;
      my $v = unpack('W', $value);
      $self->info( $v );
      $v = pack('W', $v);
      return $v;
    }
  }

=item I<info_int>

  multi method info_int() : Int
  multi method info_int(Int $value) : Int

Message I<integer> (signed integer 16-bit).

=cut

  method info_int(Maybe[Int] $value=) {
    goto SET if @_;
    GET: {
      my $v = $self->info();
      $v = 0 if not is_Int $v;
      $v = unpack('v!', pack('v!', $v));
      return $v;
    }
    SET: {
      confess unless defined $value;
      my $v = unpack('v!', pack('v!', $value));
      $self->info( $v );
      return $v;
    }
  }

=item I<info_long>

  multi method info_long() : Int
  multi method info_long(Int $value) : Int

Message I<longint> (signed integer 32-bit).

=cut

  method info_long(Maybe[Int] $value=) {
    goto SET if @_;
    GET: {
      my $v = $self->info();
      $v = 0 if not is_Int $v;
      $v = unpack('V!', pack('V!', $v));
      return $v;
    }
    SET: {
      confess unless defined $value;
      my $v = unpack('V!', pack('V!', $value));
      $self->info( $v );
      return $v;
    }
  }

=item I<info_ptr>

  multi method info_ptr() : Ref|Undef
  multi method info_ptr(Ref|Undef $value) : Ref

Message Reference.

=cut

  method info_ptr(Ref|Undef $value=) {
    goto SET if @_;
    GET: {
      return $self->info() || undef;
    }
    SET: {
      $self->info( $value );
      return $value;
    }
  };

=item I<info_word>

  multi method info_word() : Int
  multi method info_word(Int $value) : Int

Message I<word> (unsigned integer 16-bit).

=cut

  method info_word(Maybe[Int] $value=) {
    goto SET if @_;
    GET: {
      my $v = $self->info();
      $v = 0 if not is_Int $v;
      $v = unpack('v', pack('v', $v));
      return $v;
    }
    SET: {
      confess unless defined $value;
      my $v = unpack('v', pack('v', $value));
      $self->info( $v );
      return $v;
    }
  }

=item I<scan_code>

  multi method scan_code() : Int
  multi method scan_code(Int $value) : Int

Scan code.

=cut

  method scan_code(Maybe[Int] $value=) {
    goto SET if @_;
    GET: {
      my $v = $self->key_code();
      $v >>= 8;
      $v &= 0x00ff;
      return $v;
    }
    SET: {
      confess unless defined $value;
      my $v = $self->key_code();
      $v &= 0x00ff;
      $v |= $value << 8;
      $v &= 0xffff;
      $self->key_code( $v );
      return $v;
    }
  }

=item I<_stringify>

  method _stringify() : Str

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

Methods inherited from class L<Moose::Object>

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

2021-2023 by J. Schneider L<https://github.com/brickpool/>

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

Output via L</_stringify>, and parts of L</char_code> and L</scan_code>.

=over

=item *

2021 by Oleg Denisenko L<https://github.com/10der/>

=back

=head1 SEE ALSO

L<drivers.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/drivers.pas>
