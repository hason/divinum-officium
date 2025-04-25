use v5.38;
use strict;
use feature 'class';
use warnings qw(all -experimental::class);

#entries 13 (placeholder) and 14 (actually) are added for the Whole Year (Totus) Option
our $MONTHNAMES = [
  qw(''
    Januarius Februarius Martius Aprilis Maius Junius
    Julius Augustus September October November December)
];
our $MONTHLENGTH = ['', 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31, '', 365];
our $DAYNAMES = [qw(Dom. F.II F.III F.IV F.V F.VI Sabb.)];

class App::Controller::Original::Kalendar : isa(App::BaseController) {

  method calendar (@) {

    use DivinumOfficium::Globals;
    use DivinumOfficium::DialogCommon qw(getini set_runtime_options);
    use DivinumOfficium::Setup qw(getsetup loadsetup);
    use DivinumOfficium::RunTimeOptions qw(check_version);
    use DivinumOfficium::Horas::Common qw(gettoday error);

    my $compare = $self->param('compare', 0);
    my $officium = $self->param('officium', 'officium.pl');

    if ($compare) {
      $officium = "C$officium" unless $officium =~ /^[PC]/;
    } else {
      $officium =~ s/^C//;
    }

    my $date_arg = $officium =~ /Pofficium/ ? 'date1' : 'date';

    my $officium_name = $officium =~ /missa/ ? 'missa' : 'horas';
    getini("horas");

    my $ckname =
      ($officium_name =~ /officium/) ? "${officium_name}go" : ($compare) ? "${officium_name}gc" : "${officium_name}g";
    my $csname = $compare ? 'generalc' : 'general';

    my $setupsave = $self->param('setup');
    loadsetup($setupsave);

    my $format = $self->param('format', 'html');

    my $parameters = $self->request()->parameters->mixed;
    set_runtime_options($csname, $parameters);         #$expand, $version, $lang2
    $votive = 'Hodie';
    set_runtime_options('parameters', $parameters);    # priest, lang1 ... etc

    our $version1 = check_version($version) || (error("Unknown version: $version1") && 'Rubrics 1960 - 1960');
    our $version2 = check_version($version2) || '';
    if ($version1 eq $version2) { $version2 = 'Divino Afflatu - 1954'; }
    if ($version1 eq $version2) { $version2 = 'Rubrics 1960 - 1960'; }

    my ($xmonth, $xday, $xyear) = split('-', $self->param($date_arg, gettoday()));
    our $kmonth = $self->param('kmonth', $xmonth);
    our $kyear = $self->param('kyear', $xyear);

    if ($format eq 'ical') {
      return $self->ical($kyear, $version1);
    } else {
      return $self->html($kmonth, $kyear, $officium_name, $version1, $version2, $date_arg, $format);
    }
  }

  method html($kmonth, $kyear, $officium_name, $version1, $version2, $date_arg, $format) {
    use DivinumOfficium::Date qw(leapyear);

    my $mode = $kmonth == 15 ? 'calendar' : 'ordo';
    my $to = $MONTHLENGTH->[$kmonth];
    if (($kmonth == 2 || $kmonth == 14) && leapyear($kyear)) { $to++; }    # in February or for the whole year (14)

    $self->template(
      "original/calendar/$mode.html.tt", {
        mode => $mode,
        officium_name => $officium_name,
        month => $kmonth,
        to => $to,
        year => $kyear,
        version1 => $version1,
        version2 => $version2,
        date_arg => $date_arg,
        format => $format,
        MONTHNAMES => $MONTHNAMES,
        MONTHLENGTH => $MONTHLENGTH,
        DAYNAMES => $DAYNAMES,
      },
    );
  }

  method ical($year, $version1) {
    use DivinumOfficium::Date qw(leapyear ydays_to_date);
    use DivinumOfficium::Horas::Calendar qw(ordo_entry abbreviate_entry);

    my ($to) = 365 + leapyear($year);
    my (@date) = reverse((localtime(time()))[0 .. 5]);
    $date[0] += 1900;
    $date[1]++;
    my ($dtstamp) = sprintf("%04i%02i%02iT%02i%02i%02i", @date);

    my $events = [];

    for my $cday (1 .. $to) {

      my ($yday, $ymonth, $yyear) = ydays_to_date($cday, $year);
      my ($dtstart) = sprintf("%04i%02i%02i", $yyear, $ymonth, $yday);
      my $day = sprintf("%02i-%02i-%04i", $ymonth, $yday, $yyear);
      my ($entry) = ordo_entry($day, $version1, '', 'winneronly');
      my $summary = abbreviate_entry($entry);

      push @$events, {
          cday => $cday,
          summary => $summary,
          dtstart => $dtstart,
        };
    }

    my $response = $self->template(
      'original/calendar/calendar.ics.tt', {
        events => $events,
        dtstamp => $dtstamp,
      },
    );
    $response->content_type('text/calendar; charset=utf-8');
    $response->header('Content-Disposition' => "attachment; filename=\"$version1 - $year\"");

    return $response;
  }

  # findkalentry - read rank from sancti file
  method findkalentry($entry, $ver) {
    use DivinumOfficium::Globals;
    use DivinumOfficium::Main qw(liturgical_color latin_uppercase);
    use DivinumOfficium::Horas::Common qw(subdirname rankname);
    use DivinumOfficium::SetupString qw(setupstring);
    #use DivinumOfficium::Horas::Webdia qw(setfont);

    our $winner = subdirname('Sancti', $ver) . "$entry.txt";
    my %saint = %{setupstring('Latin', "$winner")};

    my @srank = split(";;", $saint{Rank});

    return '' unless $srank[0];

    our $rank = @srank[2];
    my $rankname = rankname('Latin');

    # TODO: get rid of below line when setupstring respects version conditionals
    $rankname =~ s/IV. classis/Memoria/ if $ver =~ /Monastic|Ordo Praedicatorum/;

    (
      #setfont(
      #  liturgical_color($srank[0]),
        $rank > 4 && $srank[0] !~ /octava|vigilia/i ? latin_uppercase($srank[0]) : $srank[0],
      #),
      ' ' . $rankname,#setfont('1 maroon', ' ' . $rankname),
    );
  }

  # prepare one day entry in kalendar
  method kalendar_entry($date, $ver) {
    use DivinumOfficium::Directorium qw(get_kalendar);

    $date = substr($date, 0, 5);
    my @kalentries = split('~', get_kalendar($ver, $date));
    return '' unless @kalentries;

    my $s = shift @kalentries;

    my $output = join(' ', $self->findkalentry($s, $ver));

    $output = '' if $ver =~ /1955|196/ && $date =~ /01-(?:0[7-9]|1[012])/;

    while (my $ke = shift @kalentries) {
      my ($d1, $d2) = $self->findkalentry($ke, $ver);
      $output .= ' Com. ' . $d1;
    }

    $output;
  }

  # required by kalendar.pl when dispaly Kalendarium

  # roman numbers only to 1-29 used by romanday & epactcycle
  method romannumber($d) {
    my $o;

    if ($d > 19) { $o = 'x'; $d -= 10; }
    if ($d > 9) { $o .= 'x'; $d -= 10; }

    if ($d == 9) {
      $o .= 'ix';
    } elsif ($d == 4) {
      $o .= 'iv';
    } else {
      if ($d > 4) { $o .= 'v'; $d -= 5 }
      $o .= 'i' x $d;
    }
    $o =~ s/i$/j/ unless $version =~ /196/;
    $o;
  }

  # romanday for mm-dd
  method romanday($date) {
    my $m = substr($date, 0, 2);
    my $d = substr($date, 3, 2);
    return '{Kal.}' if $d == 1;
    my $id = $m == 3 || $m == 5 || $m == 7 || $m == 10 ? 15 : 13;
    return '{Idib.}' if $d == $id;
    return '{Prid.}' if $d == ($MONTHLENGTH)[$m] || $d == ($id - 1);
    return $self->romannumber(($MONTHLENGTH)[$m] - $d + 2) if $d > $id;
    my $no = $id - 8;
    return '{Non.}' if $d == $no;
    return '{Prid.}' if $d == ($no - 1);
    return $self->romannumber($id - $d + 1) if $d > $no;
    $self->romannumber($no - $d + 1);
  }

  # dominica letter
  method domlet {
    use feature qw(state);
    state $domletc = -1;

    substr('Abcdefg', ++$domletc % 7, 1) =~ s/A/{A}/r;
  }

  # epact cycle for day of year
  method epactcycle($d) {
    use integer;
    use constant STARDAYS => (1, 31, 60, 90, 119, 149, 178, 208, 237, 267, 296, 326, 355, 385);

    return '19 {xx}' if $d == 365;

    my $i = 0;
    while ($d > (STARDAYS)[$i++]) { }

    my $r = (STARDAYS)[$i - 1] - $d;
    return '{*}' unless $r;

    my $o = '';

    if ($i % 2) {
      $r++;
      $o = '25. ' if $r == 26;
      $o = '{xxv.} ' if $r == 25;
      $r-- if $r < 26;
    } else {
      $o = '25. ' if $r == 25;
    }

    "$o\{" . $self->romannumber($r) . '}';
  }

  # prepare row
  method table_row($date, $cday) {
    use DivinumOfficium::Globals;

    my ($d) = substr($date, 3, 2) + 0;
    our ($version1, $compare, $version2);

    my ($c) = $self->kalendar_entry($date, $version1);
    $c .= '&nbsp;<br/>' . ($self->kalendar_entry($date, $version2) || '&nbsp;') if $compare;
    ($self->epactcycle($cday), $self->domlet(), $self->romanday($date), $d, $c);
  }
}
