package DivinumOfficium::Setup;

use v5.38;
use strict;
use warnings;
use utf8;
use Exporter 'import';

our @EXPORT_OK = qw(getsetup loadsetup setsetupvalue setsetup savesetup setuptable getsetupvalue);

use DivinumOfficium::Globals;
#use DivinumOfficium::DialogCommon qw(getdialog); # Cyclic dependency
use DivinumOfficium::SetupString qw(setupstring);
#use DivinumOfficium::Horas::Webdia qw(htmlInput);

my %_setup;

sub getsetup($name) {
  if (wantarray) {
    return split(',', $_setup{$name});
  } else {
    return $_setup{$name};
  }
}

sub loadsetup($setup) {
  if ($setup) {
    %_setup = split(';;;', $setup);
  } else {
    $datafolder =~ /(missa|horas)$/;
    %_setup = %{setupstring('', "$1.setup")};
  }
}

#*** setsetupvalue($name, $ind, $value)
# set $value to the $ind-th line of $setup{$name} hash item
sub setsetupvalue($name, $ind, $value) {
  my $script = $_setup{$name};
  $script =~ s/\n\s*//g;
  my @script = split(';;', $script);
  $value =~ s/^'(.*)'$/$1/;
  $script[$ind] =~ s/=.*/='$value'/;
  $_setup{$name} = join(';;', @script);
}

#*** setsetup($name, $value1, $value2 ...)
# set the values into $setup{$name} hash item
sub setsetup($name, @values) {
  for (my $i = 0; $i < @values; $i++) {
    setsetupvalue($name, $i, $values[$i]);
  }
}

#*** savesetup(\%hash, $sep)
#returns the referenced hash as key=value$sep string
sub savesetup($flag) {
  my $str = "";

  foreach (sort keys %_setup) {
    if ($flag) {
      my $value = $_setup{$_};
      $value =~ s/\;+\s*$//;
      $str .= "$_;;;$value;;;";
    } else {
      $str .= "$_=\"$_setup{$_}\",";
    }
  }
  return $str;
}

#*** setuptable($command, $title)
# generates page for options, using data from horas.dialog hash (in www/horas folder)
#
# data is a string scalar contisting on lines separated by ';;' two semicolons
# each line have 3 to 5 elements separated by '~>' sign
# labelstring~>$default~>type~>mode~>condition

sub setuptable($command, $title) {
  $title =~ s/setupparameters/Options/i;

  my $output = <<"PrintTag";
<H1 ALIGN=CENTER><FONT COLOR=MAROON><B><I>$title</I></B></FONT></H1>
<TABLE BORDER=2 CELLPADDING=5 ALIGN=CENTER$background>
PrintTag

  my $scripto = getdialog($command);
  if (!$scripto) { $error = 'No setup parameter'; return; }
  my $helpfile = "$htmlurl/help/horashelp.html";
  $helpfile =~ s/\//\\/g;

  my ($width, $rpar, @rpar, $size, @size, $range, @range, $j);
  my $i = 1;

  foreach (split(';;', $scripto)) {
    my ($parname, $parvar, $parmode, $parpar, $parpos, $parfunc, $parhelp) = split('~>');
    my $parvalue = eval($parvar);

    if (!$parpos) {
      $parpos = $i;
      $i++;
    }
    if (!$parmode) { next; }

    $output .= "<TR><TD ALIGN=left>\n";

    if ($parmode !~ /label/) {
      if ($parhelp =~ /\#/) { $output .= "<A HREF=\"$helpfile$parhelp\" TARGET='_new'>\n"; }
      $output .= "$parname\n";
      if ($parhelp =~ /\#/) { $output .= "</A>\n"; }
      $output .= " : </TD><TD ALIGN=right>";
    }
    $output .= htmlInput("I$parpos", $parvalue, $parmode, $parpar, $parfunc, $parhelp);
    $output .= "</TD></TR>\n";
  }
  $output .= <<"PrintTag";
</TABLE>
<P ALIGN=CENTER>
<INPUT TYPE=SUBMIT NAME='button' VALUE=OK>
</P>
PrintTag
  return $output;
}

#*** getsetupvalue()
# gets the input values of the table and saves the result as $name item into %setup hash
# the setup item contains $var='value' duple semicolon ;; separated lines. Value is
# changed getting param('In') values, where 'n' is a sequence number (0,1,...)
sub getsetupvalue {
  my @script;
  my @parameters = split(/;;\r?\n/, getdialog('parameters'));
  my $i = 1;

  foreach (@parameters) {
    my ($parname, $parvalue, $parmode, $parpar, $parpos, $parfunc, $parhelp) = split('~>');
    $parvalue = substr($parvalue, 1);

    if (!$parpos) {
      $parpos = $i;
      $i++;
    }
    #my $value = cleanse($q->param("I$parpos"));
    my $value;
    if (!$value && $value ne '0') { $value = ''; }
    if ($value =~ /^on$/) { $value = 1; }
    $$parvalue = $value;
    $script[$parpos - 1] = "\$$parvalue='$value'";
  }
  $_setup{'parameters'} = join(';;', @script);
}

1;
