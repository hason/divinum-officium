package App::Debug::DumperPanel;

use strict;
use warnings;
use parent 'Plack::Middleware::Debug::Base';
use Exporter 'import';

use HTML::Entities qw(encode_entities);
use Data::Dumper;

our @EXPORT_OK = qw(dump);

our $env;

sub dump {
  my ($var, $label) = @_;

  my ($pkg, $file, $line) = caller(1);

  local $Data::Dumper::Indent   = 2;
  local $Data::Dumper::Terse    = 1;
  local $Data::Dumper::Sortkeys = 1;

  my $dump = Dumper($var);

  push @{ $env->{'debug.dumper'} }, {
    label => $label // 'Dump',
    file  => $file,
    line  => $line,
    dump  => $dump,
  };
}

sub run {
  my ($self, $myenv, $panel) = @_;
  $env = $myenv;

  return sub {
    my $entries = $env->{'debug.dumper'} || [];

    $panel->title('Dumper');
    $panel->nav_title('Dumper');
    $panel->nav_subtitle(scalar(@$entries) . ' dump(s)');

    my $html = '<div class="plDebugDumper">';

    foreach my $entry (@$entries) {
      my $ref = sprintf("(%s:%d)",
        encode_entities($entry->{file}),
        $entry->{line}
      );

      $html .= "<h4>$entry->{label}</h4><i>$ref</i><pre>" . encode_entities($entry->{dump}) . "</pre>\n";
    }

    $html .= '</div>';

    $panel->content($html);
  };
}

1;
