package DivinumOfficium::Directorium;

use v5.38;
use strict;
use warnings;
use Exporter 'import';

use FindBin qw($Bin);
use DivinumOfficium::FileIO qw(do_read);
use DivinumOfficium::Date qw(leapyear geteaster get_sday nextday);

our @EXPORT_OK = qw(get_from_directorium get_kalendar get_transfer get_stransfer get_tempora transfered
  check_coronatio dirge hymnmerge hymnshift);

my $datafolder = "$Bin/data/Tabulae";
my %_data;
my %_dCACHE;    # cache everything mainly for kalendar.pl

sub load_data_data {
  my (@lines) = do_read("$datafolder/data.txt");
  if (@lines == 0) { die "Can't open $datafolder/data.txt"; }
  shift @lines;

  foreach (@lines) {
    my ($ver, $kal, $tra, $str, $base, $tbase) = split(/,/);
    $_data{$ver}{kalendar} = $kal;
    $_data{$ver}{transfer} = $tra;
    $_data{$ver}{stransfer} = $str;
    $_data{$ver}{base} = $base;
    $_data{$ver}{tbase} = $tbase;
  }
  $_dCACHE{loaded} = 1;
}

sub is_cached($key) {
  load_data_data unless defined $_dCACHE{loaded};

  defined $_dCACHE{$key};
}

sub load_transfer_file($name, $filter, $type) {
  my @lines = do_read "$datafolder/$type/$name.txt";
  my $regexp = qr{^(?:Hy|seant)?(?:01|02-[01]|02-2[01239]|dirge1)};
  my $regexp2 = qr{^(?:Hy|seant)?(?:01|02-[01]|02-2[01239]|.*=(01|02-[01]|02-2[0123])|dirge1)};

  if ($filter == 1) {    # Feb 24 - Dec
    grep { !/$regexp2/ } @lines;
  } elsif ($filter == 2) {    # Jan + Feb 23
    grep {/$regexp/} @lines;
  } else {                    # whole year
    @lines;
  }
}

sub load_kalendar($version) {
  die "Can't load kalendar for empty version" unless $version;
  die "Can't load kalendar for unknown version $version" unless defined $_data{$version};
  my $cache_key = "kalendar:$version";

  my ($filename) = "$datafolder/Kalendaria/$_data{$version}{kalendar}.txt";
  my (@lines) = do_read($filename);
  if (@lines == 0) { die "Can't open kalendar $filename for version $version"; }

  foreach (grep(/=/, @lines)) {
    my ($day, $file) = split(/=/);
    $_dCACHE{$cache_key}{$day} = $file;
  }
}

sub load_tempora($version) {
  die "Can't load tempora for empty version" unless $version;
  die "Can't load tempora for unknown version $version" unless defined $_data{$version};
  my $cache_key = "tempora:$version";

  $_dCACHE{$cache_key} = {};

  foreach (load_transfer_file($_data{$version}{transfer}, 0, 'Tempora')) {
    my ($key, $val) = split(/=/);
    $_dCACHE{$cache_key}{$key} = substr($val, 0, index($val, ';'));
  }
}

#*** load_transfer($version, $year, $stransferf)
# load transfer table based on easterday
sub load_transfer($version, $year, $stransferf = undef) {
  die "Can't load transfer for empty version" unless $version;
  die "Can't load transfer for unknown version $version" unless defined $_data{$version};
  my $type = $stransferf || 'Transfer';
  my $cache_key = lcfirst "$type:$version:$year";

  unless (is_cached($cache_key)) {

    my $isleap = leapyear($year);
    my @easter = geteaster($year);
    my $easter = $easter[1] * 100 + $easter[0];

    my $letter = ($easter - 319 + ($easter[1] == 4 ? 1 : 0)) % 7;
    my @letters = ('a', 'b', 'c', 'd', 'e', 'f', 'g');

    my @lines = load_transfer_file($letters[$letter], $isleap, $type);

    push(@lines, load_transfer_file($easter, $isleap, $type));

    if ($isleap) {    # load Jan & Feb from next file
      $easter++;
      $easter = 401 if $easter == 332;
      push(@lines, load_transfer_file($letters[$letter - 6], 2, $type));
      push(@lines, load_transfer_file($easter, 2, $type));
    }

    my (@transfer) = ();

    foreach (@lines) {
      my ($line, $ver) = split(/\s*;;\s*/);

      if (!$ver || ($ver =~ $_data{$version}{lc($type)})) {
        push(@transfer, split(/=/, $line, 2));
      }
    }

    %{$_dCACHE{$cache_key}} = @transfer;

  }

  %{$_dCACHE{$cache_key}};
}

#*** load_stransfer($version, $year)
# load scriptura transfer
sub load_stransfer($version, $year) {
  load_transfer($version, $year, 'Stransfer');
}

### public functions

### get_from_directorium($subject, $version, $key, $year)
# returns value for $key (ev $year) in specified $version of
# 'kalendar|tempora|transfer|stransfer' from files located in
# Tabulae subdirectories
sub get_from_directorium($subject, $version, $key, $year = undef) {
  my $cache_key = "$subject:$version";
  $cache_key .= ":$year" if $year;
  my $base = $subject eq 'kalendar' ? 'base' : 'tbase';

  no strict;

  &{"load_$subject"}($version, $year) unless is_cached $cache_key;

  $_dCACHE{$cache_key}{$key}
    || ($_data{$version}{$base} && get_from_directorium($subject, $_data{$version}{$base}, $key, $year))
    || '';
}

# returns destination if the day for season or saint is transfered
# otherwise false
sub transfered($str, $year, $version) {
  $str =~ s+SanctiM?/++;
  return '' unless $str;

  my %transfer = %{$_dCACHE{"transfer:$version:$year"}};

  while (my ($key, $val) = each %transfer) {
    next unless $val;
    next if $key =~ /(dirge|Hy)/i;

    if ($val =~ /Tempora/i && $val !~ /Epi1\-0/i) { next; }

    if ($val !~ /^$key/ && ($str =~ /$val/i || $val =~ /$str/i) && $transfer{$key} !~ /v\s*$/i) {
      return $key;
    }
  }

  while (my ($key, $val) = each %{$_dCACHE{"tempora:$version"}}) {
    next if $key =~ /dirge/;

    if ($val =~ /$str/i && $transfer{$key} && $transfer{$key} !~ /v\s*$/i) { return $key; }
  }

  return '';
}

# date should be taken from data file
# and conformed with year transfer table
sub check_coronatio($day, $month) {
  $day == 20 && $month == 3 ? 'Commune/Coronatio' : '';
}

# check if defunctorum shoul be said after hora
sub dirge($version, $hora, $day, $month, $year) {
  return 0 unless $hora =~ /Vespera|Laudes/i;

  my $sday =
    $hora =~ /Laudes/i
    ? get_sday($month, $day, $year)
    : nextday($month, $day, $year);
  my $dirgeline =
      get_from_directorium('transfer', $version, 'dirge1', $year) . ' '
    . get_from_directorium('transfer', $version, 'dirge2', $year) . ' '
    . get_from_directorium('transfer', $version, 'dirge3', $year);
  $dirgeline =~ /$sday/;
}

# true if Matutinum Hymn should merged with Vesperas
# Rule XX.3
sub hymnmerge($version, $day, $month, $year) {
  get_from_directorium("transfer", $version, sprintf("Hy%s", get_sday($month, $day, $year)), $year) eq '1';
}

# true if Hymns should shifted Vespera > Matutinum > Laudes > Vespera
# Rule XX.3
sub hymnshift($version, $day, $month, $year) {
  get_from_directorium("transfer", $version, sprintf("Hy%s", get_sday($month, $day, $year)), $year) eq '2';
}
