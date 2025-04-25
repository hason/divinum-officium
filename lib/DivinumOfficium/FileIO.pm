package DivinumOfficium::FileIO;

use v5.38;
use strict;
use warnings;
use utf8;
use Exporter 'import';

# Text-based IO for Divinum Officium Project.
our @EXPORT_OK = qw(do_read do_write);

# Read a data file, assumed to be text, and return array of its lines.
# Returns () if nothing can be read.
sub do_read($file) {
  open(my $in, '<:encoding(UTF-8)', $file) or return ();
  local $/;    # Slurp
  my $content = <$in>;
  close $in;
  return () unless $content;
  $content =~ s/^\x{FEFF}//;
  return split /\r?\n/, $content;
}

# Now we're in charge.  Write in utf-8, never mind.
sub do_write($file, @content) {
  open(my $out, ">:encoding(utf-8)", $file) or return;
  print $out for @content;
  close $out;
  return 1;
}
