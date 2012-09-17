#!/dev/nul
use strict;
use warnings;

package DataUnits;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(dechex word dword qword float readword readdword readqword readfloat);

our $sixtyfour = eval("pack('Q',1) ? 1 : 0");
warn('You are running Vaffel on a 32-bit platform!') if !$sixtyfour;

sub dechex { uc(sprintf('%0' . ($_[1] || 2) . 'lx',int($_[0] || 0))) }

sub word	{ pack('S',$_[0]) }
sub dword	{ pack('L',$_[0]) }
sub qword	{ $sixtyfour ? pack('Q',$_[0]) : dword($_[0]) . dword(0) }
sub float	{ pack('f',$_[0]) }

sub readword	{ unpack('S',$_[0]) }
sub readdword	{ unpack('L',$_[0]) }
sub readqword	{ $sixtyfour ? unpack('Q',$_[0]) : unpack('L',substr($_[0],0,4)) }
sub readfloat	{ unpack('f',$_[0]) }

return 1;
