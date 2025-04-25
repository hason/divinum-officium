package DivinumOfficium::RunTimeOptions;

use v5.38;
use utf8;
use strict;
use warnings;
use Exporter 'import';

use DivinumOfficium::DialogCommon qw(getdialog);

our @EXPORT_OK = qw(check_version check_horas check_language);

sub unequivocal($value, $tablename) {
  my @values_array = getdialog($tablename);

  my @r = grep {/$value/} @values_array;

  if (@r == 1) {
    return $r[0] =~ s/.*\///r;
  } else {
    @r = grep { $_ eq $value } @values_array;

    if (@r == 1) {
      return $r[0] =~ s/.*\///r;
    } else {
      return;
    }
  }
}

use constant LEGACY_VERSION_NAMES => {
  'Tridentine 1570' => 'Tridentine - 1570',
  'Tridentine 1910' => 'Tridentine - 1906',
  'Rubrics 1960' => 'Rubrics 1960 - 1960',
  'Reduced 1955' => 'Reduced - 1955',
  'Monastic' => 'Monastic - 1963',
  '1960 Newcalendar' => 'Rubrics 1960 - 2020 USA',
  'Dominican' => 'Ordo Praedicatorum - 1962',

  # safeguard switch from missa to horas
  'Tridentine - 1910' => 'Tridentine - 1906',
  'Ordo Praedicatorum Dominican 1962' => 'Ordo Praedicatorum - 1962',
  'Rubrics 1960 Newcalendar' => 'Rubrics 1960 - 2020 USA',
};

use constant LEGACY_MISSA_VERSION_NAMES => {
  'Tridentine 1570' => 'Tridentine - 1570',
  'Tridentine 1910' => 'Tridentine - 1910',
  'Rubrics 1960' => 'Rubrics 1960 - 1960',
  'Reduced 1955' => 'Reduced - 1955',
  '1960 Newcalendar' => 'Rubrics 1960 - 2020 USA',
  'Dominican' => 'Ordo Praedicatorum Dominican 1962',

  # safeguard switch from horas to missa
  'Monastic Tridentinum 1617' => 'Tridentine - 1570',
  'Monastic Divino 1930' => 'Divino Afflatu - 1939',
  'Monastic - 1963' => 'Rubrics 1960 - 1960',
  'Monastic Tridentinum Cisterciensis 1951' => 'Tridentine - 1910',
  'Monastic Tridentinum Cisterciensis Altovadensis' => 'Reduced - 1955',
  'Tridentine - 1888' => 'Tridentine - 1910',
  'Tridentine - 1906' => 'Tridentine - 1910',
  'Ordo Praedicatorum - 1962' => 'Ordo Praedicatorum Dominican 1962',
};

sub check_version($v, $missa = undef) {
  return unless $v;

  if (!$missa) {
    return LEGACY_VERSION_NAMES->{$v} || unequivocal($v, 'versions');
  } else {
    return LEGACY_MISSA_VERSION_NAMES->{$v} || unequivocal($v, 'versions');
  }
}

sub check_horas($h) {
  map { unequivocal($_, 'horas') } split(/(?=\p{Lu}\p{Ll}*)/, $h);
}

sub check_language($l) {
  unequivocal($l, 'languages');
}
