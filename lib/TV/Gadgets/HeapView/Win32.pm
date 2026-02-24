package TV::Gadgets::HeapView::Win32;
# ABSTRACT: on Windows, display the virtual memory used by the process

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Config;
use PerlX::Assert::PP;
use Scalar::Util qw( blessed );
use Win32::API;

use constant PTR_SIZE => $Config{ptrsize};
use constant SIZE_T =>
    PTR_SIZE == 8 ? 'Q'
  : PTR_SIZE == 4 ? 'L'
  : die "Unrecognized ptrsize\n";

# Set the size large enough for Windows 32 and 64 bit versions
use constant PROCESS_MEMORY_COUNTERS_EX_SIZE => ( 2 * 4 + 9 * PTR_SIZE );

use constant {
  # cb                         =>  0,  # DWORD
  # PageFaultCount             =>  1,  # DWORD
  # PeakWorkingSetSize         =>  2,  # SIZE_T
  # WorkingSetSize             =>  3,  # SIZE_T
  # QuotaPeakPagedPoolUsage    =>  4,  # SIZE_T
  # QuotaPagedPoolUsage        =>  5,  # SIZE_T
  # QuotaPeakNonPagedPoolUsage =>  6,  # SIZE_T
  # QuotaNonPagedPoolUsage     =>  7,  # SIZE_T
  # PagefileUsage              =>  8,  # SIZE_T
  # PeakPagefileUsage          =>  9,  # SIZE_T
  PrivateUsage               => 10,  # SIZE_T
};

BEGIN {
  # Load required Windows API functions
  Win32::API::More->Import( 'kernel32', 
    'HANDLE GetCurrentProcess()'
  ) or die "Import GetCurrentProcess failed: $^E";

  Win32::API::More->Import( 'psapi', 
    'BOOL GetProcessMemoryInfo(
      HANDLE Process,
      LPVOID ppsmemCounters,
      DWORD  cb
    )'
  ) or die "Import GetProcessMemoryInfo failed: $^E";
}

sub heapSize {    # $total ()
  my ( $self ) = @_;
  assert { @_ == 1 };
  assert { blessed $self };
  alias: for my $totalStr ( $self->{heapStr} ) {
  $totalStr = "     No heap";

  # Get process handle
  my $hProcess = GetCurrentProcess();
  return -1 unless defined $hProcess && $hProcess != -1;

  # Create pmc buffer for PROCESS_MEMORY_COUNTERS_EX
  my $buf = "\0" x PROCESS_MEMORY_COUNTERS_EX_SIZE;

  # Call WinAPI to fill memory info
  my $r = GetProcessMemoryInfo( $hProcess, $buf, 
    PROCESS_MEMORY_COUNTERS_EX_SIZE );
  return -1 unless $r;

  # Unpack PROCESS_MEMORY_COUNTERS_EX
  my @pmc = unpack( 'LL' . SIZE_T . '*', $buf );

  # Prepare display string similar to setw(12)
  $totalStr = sprintf( "%12d", $pmc[PrivateUsage] );

  return $pmc[PrivateUsage];
  }
} #/ sub heapSize

1
