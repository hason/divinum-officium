use utf8;
use strict;
use feature 'class';
use warnings qw(all -experimental::class);

use POSIX;
use FindBin qw($Bin);
use File::Basename;
use Template;
use Time::Local;

#use DateTime;
use locale;
use DivinumOfficium::Main qw(vernaculars liturgical_color);
use DivinumOfficium::LanguageTextTools
  qw(prayer translate load_languages_data omit_regexp suppress_alleluia process_inline_alleluias alleluia_ant ensure_single_alleluia ensure_double_alleluia);
use DivinumOfficium::RunTimeOptions qw(check_version check_language);
use DivinumOfficium::Globals;

$error = '';
$debug = '';

our $Ck = 0;
our $missa = 1;
our $NewMass = 0;
our $officium = 'missa.pl';
our $comrank = 0;

getini('missa');    #files, colors

our $testmode;
our $votive;
our $first = strictparam('first');
our $Propers = strictparam('Propers');
our $command = strictparam('command');
our $browsertime = strictparam('browsertime');
our $searchvalue = strictparam('searchvalue');

if (!$searchvalue) { $searchvalue = '0'; }
our $missanumber = strictparam('missanumber');
if (!$missanumber) { $missanumber = 1; }
our $caller = strictparam('caller');

$setupsave = strictparam('setupm');
loadsetup($setupsave);

if (!$setupsave) {
  getcookies('missap', 'parameters');
  getcookies('missag', 'general');
}

set_runtime_options('general');       #$expand, $version, $lang2
set_runtime_options('parameters');    # priest, lang1 ... etc

if ($command eq 'changeparameters') { getsetupvalue($command); }

#print "Content-type: text/html; charset=utf-8\n\n"; <= uncomment for debuggin "Internal Server Errors"
$version = check_version($version, $missa) || (error("Unknown version: $version") && 'Rubrics 1960 - 1960');
$lang1 = check_language($lang1) || (error("Unknown language: $lang1") && 'Latin');
$lang2 = check_language($lang2) || 'English';
$langfb = check_language($langfb) || 'English';

setcookies('missap', 'parameters');
setcookies('missag', 'general');

# save parameters
$setupsave = savesetup(1);
$setupsave =~ s/\r*\n*//g;

#*** handle different actions
#after setup

if ($testmode !~ /(Seasonal|Season|Saint)/i) { $testmode = 'regular'; }
$rubrics = strictparam('rubrics');
$solemn = strictparam('solemn');

$only = ($lang1 =~ /$lang2/) ? 1 : 0;

# save parameters
precedence();    #fills our hashes et variables
setsecondcol();

#prepare main pages
$title = "Sancta Missa";

#*** print pages (setup, hora=pray, mainpage)
#generate HTML
$background = ($whitebground) ? ' class="contrastbg"' : '';

$tt = Template->new(
  START_TAG => quotemeta('{%'),
  END_TAG => quotemeta('%}'),
  INCLUDE_PATH => "$Bin/..",
  INTERPOLATE => 0,
  FILTERS => {html => \&html_filter},
);
$tt->process(
  'missa.html.tt', {
    title => $title,
    onload => 'startup()',
    background => $background,
    lang1 => $lang1,
    lang2 => $lang2,
    langfb => $langfb,
    version => $version,
    missa => $missa,
    testmode => $testmode,
    setupsave => $setupsave,
    screenwidth => $screenwidth,
    screenheight => $screenheight,
  },
);

if ($command =~ /setup(.*)/is) {
  $pmode = 'setup';
  $command = $1;
  print setuptable($command, $title);
  $command = "change" . $command;
} elsif ($command =~ /pray/i) {
  $pmode = 'missa';
  $command =~ s/(pray|change|setup)//ig;
  $head = $title;
  headline($head);
  load_languages_data($lang1, $lang2, $langfb, $version, $missa);

  #eval($setup{'parameters'});
  $background = ($whitebground) ? ' class="contrastbg"' : '';
  ordo();
  print <<"PrintTag";
<INPUT TYPE=HIDDEN NAME=expandnum VALUE="">
PrintTag
} else {    #mainpage
  $pmode = 'main';
  $command = "";
  $height = floor($screenheight * 6 / 12);
  headline($title);
  print <<"PrintTag";
<P ALIGN=CENTER>
<TABLE BORDER=0 HEIGHT=$height><TR>
<TD><IMG SRC="$htmlurl/missa.png" HEIGHT=$height></TD>
</TR></TABLE>
<BR>
</P>
PrintTag
}

if ($pmode =~ /(main|missa)/i) {

  #common widgets for main and hora
  $crubrics = ($rubrics) ? 'CHECKED' : '';
  $csolemn = ($solemn) ? 'CHECKED' : '';
  @chv = splice(@chv, @chv);
  $ctext = ($pmode =~ /(main)/i) ? 'Sancta Missa' : 'Sancta Missa Persoluta';
  print <<"PrintTag";
<P ALIGN=CENTER><FONT SIZE=+1><I>
<LABEL FOR=rubrics>Rubrics : </LABEL><INPUT ID=rubrics TYPE=CHECKBOX NAME='rubrics' $crubrics Value=1  onclick="parchange()">
&nbsp;&nbsp;&nbsp;
<A HREF=# onclick="hset('$ctext');"><FONT COLOR=blue>$ctext</FONT></A>
&nbsp;&nbsp;&nbsp;
<LABEL FOR=solemn>Solemn : </LABEL><INPUT ID=solemn TYPE=CHECKBOX NAME='solemn' $csolemn Value=1 onclick="parchange()">
</I></P>
<P ALIGN=CENTER>
PrintTag

  #$testmode = 'Regular' unless $testmode;
  #if ($savesetup > 1) {
  #  print option_selector("testmode", "parchange();", $testmode, qw(Regular Seasonal Season Saint Common));
  #} else {
  #  print option_selector("testmode", "parchange();", $testmode, qw(Regular Seasonal));
  #}
  print(selectables('general' . ($Ck ? 'c' : '')));
  print "</P>\n";
  my $propname = ($Propers) ? 'Full' : 'Propers';
  print qq(<P ALIGN=CENTER><FONT SIZE=+1>\n<A HREF=# onclick="hset('Propers')">$propname</A>\n</FONT></P>\n);
  print "<P ALIGN=CENTER><FONT SIZE=+1>\n" . bottom_links_menu() . "</FONT>\n</P>\n";
}

# This procedure handles days on which there qre more than one proper Mass.
# It returns HTML offering the choice as a radio button sequence.
sub setmissanumber {
  our $missanumber;
  my $str;

  if ($winner{Rule} =~ /(multiple|celebranda aut\s+)(.*)/) {
    my $object = $2;
    my $lim;
    my @missae;

    if ($object =~ /[0-9]/) {
      @missae = 1 .. $object;
    } else {
      @missae = split /\baut\s+/i, $object;
    }
    my $i = 0;

    for (@missae) {
      $i = $i + 1;
      my $m = $i == $missanumber ? 'checked' : '';
      s/\bmissa/Missa/;
      $str .= "<input type='radio' $m onclick='parchange();' name='missanumber' value='$i'>$_</input>&nbsp;";
    }
  } else {
    $str = '';
  }
  return $str;
}
