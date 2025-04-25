package DivinumOfficium::Main;

use v5.38;
use utf8;
use strict;
use warnings;
use Exporter 'import';

use DivinumOfficium::FileIO qw(do_read);

our @EXPORT_OK = qw(vernaculars liturgical_color latin_uppercase);

# Returns a list of available vernacular languages for the datafiles rooted at
# $basedir.
sub vernaculars($basedir) {
  my @lines = do_read("$basedir/Linguae.txt") or die q(Couldn't load language list.);
  return @lines;
}

sub liturgical_color ($text) {
  return 'blue' if ($text =~ /(?:Beat|Sanct)(?:ae|æ) Mari/ && $text !~ /Vigil/);
  return 'red' if ($text =~ /(?:Vigilia Pentecostes|Quattuor Temporum Pentecostes|Decollatione|Martyr)/i);
  return 'grey' if ($text =~ /(?:Defunctorum|Parasceve|Morte)/i);
  return 'black' if ($text =~ /^In Vigilia Ascensionis|^In Vigilia Epiphaniæ/);
  return 'purple'
    if (
      $text =~ /(?:Vigilia|Quattuor|Rogatio|Passion|Palmis|gesim|(?:Majoris )?Hebdomadæ(?: Sanctæ)?|Sabbato Sancto|Dolorum|Ciner|Adventus)/i
    );
  return 'black' if ($text =~ /(?:Conversione|Dedicatione|Cathedra|oann|Pasch|Confessor|Ascensio|Cena)/i);
  return 'green' if ($text =~ /(?:Pentecosten(?!.*infra octavam)|Epiphaniam|post octavam)/i);
  return 'red' if ($text =~ /(?:Pentecostes|Evangel|Innocentium|Sanguinis|Cruc|Apostol)/i);
  return 'black';
}

# latin uppercase
sub latin_uppercase {
  local ($_) = shift;
  s/.*/\U$&/;
  s/æ/Æ/rg;
}
