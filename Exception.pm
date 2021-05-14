package Exception;

use strict;

require Exporter;
our @ISA = qw(Exporter);

$Exception::msg = 'Exception:';
# XXX itt most akkor kell a package-név vagy nem?

sub isExc { $_[0] =~ m/^$Exception::msg/ ? 1 : ''; }

