package DivinumOfficium::Horas::Calendar;

use v5.38;
use strict;
use warnings;
use utf8;
use Exporter 'import';

our @EXPORT_OK = qw(ordo_entry abbreviate_entry);

use DivinumOfficium::Globals;
use DivinumOfficium::Horas::Common qw(precedence setheadline);

# prepare one day entry in ordo
sub ordo_entry($date, $ver, $compare, $winneronly) {
  our $version = $ver;
  our ($day, $month, $year, $dayname, %scriptura, @commemoentries, $winner);

  precedence($date);

  my ($h1, $h2) = split(/\s*~\s*/, setheadline());
  return "$h1, $h2" if $winneronly;    # finish here for ical

=cut
  my ($c1, $c2);
  $c1 = "<B>" . setfont(liturgical_color($h1), $h1) . "</B>" . setfont('1 maroon', "&ensp;$h2");
  $c1 =~ s/Hebdomadam/Hebd/i;
  $c1 =~ s/Quadragesima/Quadr/i;

  $c2 = $dayname[2];

  ($h1, $h2) = split(/: /, $c2, 2);
  $h2 =~ s/(\(Scriptura ut in\: .*\))//;
  my $scripturaUt = $1;
  ($c2, $h1, $h2) = ('', '', $h1) unless $h2;
  $c2 = setfont($smallblack, "$h1:") if $h1;
  $c2 .= "<I>" . setfont(liturgical_color($h2), " $h2") . "</I>" if $h2;
  $c2 .= "<I>" . setfont($smallblack, " $scripturaUt") . "</I>" if $scripturaUt;

  if ($c2 && @commemoentries > 1) {
    for my $ind (1 .. @commemoentries - 1) {
      my %com = %{setupstring('Latin', "$commemoentries[$ind].txt")};
      my $comname = $com{Rank};
      $comname =~ s/\;\;.*//;
      $c2 .= " <I>&amp; " . setfont(liturgical_color($comname), " $comname") . "</I>" if $comname;
    }
  }

  $c2 =~ s/Hebdomadam/Hebd/i;
  $c2 =~ s/Quadragesima/Quadr/i;

  if (
       $version !~ /196/
    && $winner =~ /Sancti/
    && (
      (
           exists($winner{Lectio1})
        && $winner{Lectio1} !~ /\@Commune/i
        && $winner{Lectio1} !~ /\!(Matt|Marc|Luc|Joannes)\s+[0-9]+\:[0-9]+\-[0-9]+/i
      )
      || ($winner{Rule} =~ /In 1 nocturno lectiones ex commune/i)
    )
    && !($winner{Rule} =~ /Lectio1 Quad/i && $dayname[0] !~ /Quad(\d|p3\-[3456])/i)
  ) {
    $c1 .= setfont($smallfont, " *L1*");
  }

  if (substr($date, 0, 5) lt '12-24' && substr($date, 0, 5) gt '01-13') {

    # outside Nat put Sancti winner in right column
    ($c2, $c1) = ($c1, $c2) if $winner =~ /sancti/i;
  } else {

    # inside Nat clear right column unless it is commemoratio of saint or scriptura
    $c2 = '' unless $c2 =~ /Commemoratio|Scriptura/;
  }

  if (dirge($version, 'Laudes', $day, $month, $year)) { $c1 .= setfont($smallblack, ' dirge'); }
  if ($version !~ /1960/ && $initia) { $c1 .= setfont($smallfont, ' *I*'); }

  if ($version !~ /1955|196/ && $winner{Rule} =~ /\;mtv/i) {
    $c2 .= setfont($smallblack, ' m.t.v.');
  }

  our $hora;
  my $temphora = $hora;
  $hora = 'Vespera';
  precedence($date);
  $hora = $temphora;
  my $cv = $dayname[2];
  $cv =~ s/.*?(Vespera|A capitulo|$)/$1/;

  if ($compare) {
    $c2 ||= '_';
    $cv ||= '_';
  }
  return ($c1, $c2, $cv);
=cut

}

# abbreviate entries for ical
sub abbreviate_entry($entry) {
  s/Duplex majus/dxm/;
  s/Duplex/dx/;
  s/Semiduplex/sdx/;
  s/Simplex/splx/;
  s/classis/cl./;
  s/ Domini Nostri Jesu Christi/ D.N.J.C./;
  s/Beatæ Mariæ Virginis/B.M.V./;
  s/Abbatis/Abb./;
  s/Apostoli/Ap./;
  s/Apostolorum/App./;
  s/Confessor\w+/Conf./g;
  s/Doctoris/Doct./;
  s/Ecclesiæ/Eccl./;
  s/Episcopi/Ep./;
  s/Episcoporum/Epp./;
  s/Evangelistæ/Evang./;
  s/Martyris/M./g;
  s/Martyrum/Mm./g;
  s/Papæ/P./g;
  s/Viduæ/Vid./;
  s/Virgin\w+/Vir./;
  s/Hebdomadam/Hebd./i;
  s/Quadragesim./Quad./i;
  s/Secunda/II/;
  s/Tertia/III/;
  s/Quarta/IV/;
  s/Quinta/V/;
  s/Sexta/VI/;
  s/Dominica minor/Dom. min./;
  s/ Ferial//;
  s/Feria major/Fer. maj./;
  s/Feria privilegiata/Fer. priv./;
  s/post Octavam/post Oct./;
  s/Augusti/Aug./;
  s/(Septem|Octo|Novem|Decem)bris/${1}b./;
  $entry;
}
