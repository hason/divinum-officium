package DivinumOfficium::DialogCommon;

use v5.38;
use strict;
use warnings;
use FindBin qw($Bin);
use Exporter 'import';

our @EXPORT_OK = qw(getini chompd getdialog gethoras set_runtime_options version_displayname);

use DivinumOfficium::Globals;
use DivinumOfficium::FileIO qw(do_read);
use DivinumOfficium::Setup qw(getsetup setsetupvalue);
use DivinumOfficium::SetupString qw(setupstring);

#*** getini(file)
# loads and interprets .ini file
# the file consists of $var='value' lines
sub getini($file) {
  my $path = "$Bin/config/$file.ini";
  my @lines = do_read($path);

  foreach my $line (@lines) {
    $line =~ s/^\s*\$(\w+)\s*=/\$DivinumOfficium::Globals::$1 =/;
    eval $line;
  }
}

#*** chompd($str)
# removes the newline characters from the end of the string
# returns the modified string
sub chompd($a) {
  chomp($a);
  $a =~ s/\r//g;
  return $a;
}

my %_dialog;

#*** getdialog($name, $sep, $col)
# returns the array of the $col-th column from $dialog{$name} hash element
# the hash value is cleared from newline characters and is split
# into and string array where the elements are separated by , comma
# Each string is split by $sep separator, and the $col-th element
# of this split is collected onto the returned array.
sub getdialog($name) {
  our $datafolder;

  if (!$_dialog{'loaded'}) {
    $datafolder =~ /(missa|horas)$/;
    %_dialog = %{setupstring('', "$1.dialog")};
    foreach (keys %_dialog) { chomp($_dialog{$_}) }
    $_dialog{'loaded'} = 1;
  }
  chomp($_dialog{$name});

  if (wantarray) {
    return split(',', $_dialog{$name});
  } else {
    return $_dialog{$name};
  }
}

sub gethoras($C9f) {
  my @horas = getdialog('horas');
  @horas = @horas[0, 1, 6] if ($C9f);
  $horas[-1] =~ s/\s*$//;
  @horas;
}

sub set_runtime_options($name, $params) {
  my @parameters = split(/;;\r?\n/, getdialog($name));

  # pop(@parameters);
  my @setupt = split(/;;/, getsetup($name));

  # pop(@setupt);
  my $p;
  my $i = 1;

  foreach (@parameters) {
    my ($parname, $parvalue, $parmode, $parpar, $parpos, $parfunc, $parhelp) = split('~>');

    if ($parpos !~ /^\d+$/) {
      $parpos = $i;
      $i++;
    }
    $parvalue = substr($parvalue, 1);

    if ($p = %$params{$parvalue} // '') {
      setsetupvalue($name, $parpos - 1, $p);
    } else {
      $p = substr($setupt[$parpos - 1], index($setupt[$parpos - 1], '=') + 2, -1);
    }
    $DivinumOfficium::Globals::{$parvalue} = $p;
  }
  $blackfont =~ s/black//;    # can't use black in contrast mode
  $smallblack =~ s/black//;
}

#*** version_displayname
# outputs version name for display (part before '/')
sub version_displayname($version) {
  my $s = getdialog('versions');
  my $i = index($s, $version) - 1;

  if ($i == -1 || (substr($s, $i, 1) eq ',')) {
    $version;
  } else {
    my $k = rindex(substr($s, 0, $i - 1), ',') + 1;
    substr($s, $k, $i - $k);
  }
}
