package TV::Views::WindowInit;
# ABSTRACT: A class for initializing a frame for TWindows.

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TWindowInit
  new_TWindowInit
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw( blessed );

use TV::toolkit;

sub TWindowInit() { __PACKAGE__ }
sub new_TWindowInit { __PACKAGE__->from(@_) }

# declare attributes
has createFrame => ( is => 'bare', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args = STRICT ? check( {
    cFrame => { required => 1, default => sub { }, strict_type => 1 },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
  # 'init_arg' is not equal to the field name
  $args->{createFrame} = delete $args->{cFrame};
  return $args;
}

sub from {    # $obj ($cFrame)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 1 );
  return $class->new( cFrame => $_[0] );
}

sub createFrame {    # $frame ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  return $self->{createFrame}->( bounds => $r );
}

1

__END__

=pod

=head1 NAME

TWindowsInit - A class for initializing a frame for TWindows.

=head1 SYNOPSIS

  use TV::Views;

  my $winInit = TWindowsInit->new($cFrame => sub { ... } );

=head1 DESCRIPTION

The TWindowsInit class is used to initialize the frame in TWindows. It provides 
methods to start and complete the initialization process. This class is 
essential for setting up the user interface elements in a TWindow class.

=head1 ATTRIBUTES

=over

=item createFrame

A subroutine reference used to create the frame for a window. (CodeRef)

=back

=head1 METHODS

=head2 new

  my $obj = TWindowInit->new(%args);

Initializes the code reference for a frame.

=over

=item cFrame

Required parameter to specify the frame creation subroutine. (CodeRef)

=back

=head2 from

  my $obj = TWindowInit->from($cFrame);

Creates a TWindowInit object from the specified frame creation subroutine.

=head2 createFrame

  my $frame = $self->createFrame($r);

Creates the frame for a TWindow using the specified TRect parameter $r.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2025 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
