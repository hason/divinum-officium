package DivinumOfficium::LanguageTextTools;

use v5.38;
use strict;
use warnings;
use utf8;
use Exporter 'import';

use DivinumOfficium::SetupString qw(setupstring);

our @EXPORT_OK = qw(prayer rubric prex translate load_languages_data
  omit_regexp suppress_alleluia process_inline_alleluias
  alleluia_ant ensure_single_alleluia ensure_double_alleluia);

my %_translate;
my %_prayers;
my %_preces;
my %_rubrics;
my $alleluia_regexp;
my $omit_regexp;
my $fb_lang;

sub alleluia($lang) {
  my $text = prayer('Alleluia', $lang);
  $text =~ s/^v. (.*?)\..*/$1/rs;
}

# Removes all alleluia
sub suppress_alleluia($text_ref) {
  $$text_ref =~ s/[,.]?\s*$alleluia_regexp//ig;
}

# unbrackets bracketed alleluias when $paschalf is true
# removes bracketed alleluias otherwise
sub process_inline_alleluias($text_ref, $paschalf) {
  if ($paschalf) {
    $$text_ref =~ s/\(($alleluia_regexp.*?)\)/ $1 /isg;
  } else {
    $$text_ref =~ s/\($alleluia_regexp.*?\)//isg;
  }
}

# Ensures that $text ends in a single 'alleluia' (or rather the
# appropriate translation for $lang).
sub ensure_single_alleluia($text_ref, $lang) {
  # Add a single 'alleluia', unless it's already there.
  $$text_ref =~ s/\p{P}?\s*$/ ", " . lc(alleluia($lang)) . '.'/e
    unless $$text_ref =~ /$alleluia_regexp\p{P}?\)?\s*$/ || !$$text_ref;
}

# Arranges that $text should end in a double 'alleluia' (or rather the
# appropriate translation for $lang), and that the asterisk should be
# placed correctly, if it appears that the response is not already in
# the Paschal form.
sub ensure_double_alleluia($text_ref, $lang) {
  my $alleluia = prayer('Alleluia Duplex', $lang);
  $alleluia =~ s/\s+$//;

  if ($$text_ref !~ /$alleluia_regexp[,.] $alleluia_regexp\p{P}?\s*$/i) {

    # Add a double 'alleluia' and move the asterisk.
    $$text_ref =~ s/\s*\*\s*(.)/ \l$1/;
    $$text_ref =~ s/\p{P}?\s*$/', * ' . alleluia($lang) . ', ' . lc(alleluia($lang) . '.')/e;
  }
}

# 'Alleluja * alleluja, alleluja.'
sub alleluia_ant($lang) {
  my $u = alleluia($lang);
  my $l = lc $u;

  "$u, * $l, $l.";
}

sub omit_regexp {
  $omit_regexp;
}

# return the translated name
sub translate($name, $lang) {
  my $prefix = '';
  if ($name =~ s/^([\$&])//) { $prefix = $1; }

  return $prefix . ($_translate{Latin}{$name} =~ s/\s*$//r || $name) if $lang =~ /Latin/;

  my $output =
    $prefix . ($_translate{$lang}{$name} || $_translate{$main::langfb}{$name} || $_translate{Latin}{$name} || $name);
  $output =~ s/\s*$//r;
}

# return the prayer
sub prayer($name, $lang) {
  our $version;

  my $prayer =
       $_prayers{"$lang$version"}{$name}
    || $_prayers{"$fb_lang$version"}{$name}
    || $_prayers{"Latin$version"}{$name}
    || $name;

  if ($version =~ /cist/i && $name !~ /Pater Ave|Incipit|clara|bene.*Final/i) {
    $prayer =~ s/\++ //g;
  }
  return $prayer;
}

# return the prayer
sub rubric($name, $lang) {
  our $version;

       $_rubrics{"$lang$version"}{$name}
    || $_rubrics{"$fb_lang$version"}{$name}
    || $_rubrics{"Latin$version"}{$name}
    || $name;
}

# return the prayer
sub prex($name, $lang) {
  our $version;

       $_preces{"$lang$version"}{$name}
    || $_preces{"$fb_lang$version"}{$name}
    || $_preces{"Latin$version"}{$name}
    || $name;
}

sub load_languages_data($lang1, $lang2, $langfb, $version, $missaf) {
  my @langs = ('Latin', $lang1, $lang2, $langfb);

  # take unique values from @langs
  @langs = do {
    my %seen;
    grep { !$seen{$_}++ } @langs;
  };

  # save fallabck lang for local module use
  $fb_lang = $langfb;

  my $dir = $missaf ? 'Ordo' : 'Psalterium/Common';

  foreach my $lang (@langs) {
    $_prayers{"$lang$version"} = setupstring($lang, "$dir/Prayers.txt");
    $_rubrics{"$lang$version"} = setupstring($lang, "Psalterium/Common/Rubricae.txt");
    $_preces{"$lang$version"} = setupstring($lang, "Psalterium/Special/Preces.txt");
    $_translate{$lang} = setupstring($lang, "Psalterium/Common/Translate.txt");
  }

  my $alleluias = join('|', map { lc(alleluia($_)) } @langs);
  $alleluias .= '|allel[uú][ij]a';    # alternative spelling in Latin
  $alleluia_regexp = qr/(?:\L$alleluias)/i;

  my $omits = join(
    '|',
    map {
      my %comm = %{setupstring($_, 'Psalterium/Comment.txt')};
      (split("\n", $comm{'Preces'}))[1] . '|' . (split("\n", $comm{'Suffragium'}))[0];
    } @langs,
  );
  $omit_regexp = qr/\b(?:$omits)\b/;
}
