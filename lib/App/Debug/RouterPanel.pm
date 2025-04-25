package App::Debug::RouterPanel;

use strict;
use warnings;
use parent 'Plack::Middleware::Debug::Base';
use HTML::Entities qw(encode_entities);
use Scalar::Util 'blessed';

sub run {
  my ($self, $env, $panel) = @_;
  return sub {
    my $container = $env->{'container'} // {};
    my $data = {};

    if (blessed($container) && $container->isa('App::Container')) {
      $data = $container->router()->processed_routes();
    }

    $panel->title('Routes');
    $panel->nav_title('Routes');
    $panel->nav_subtitle($self->subtitle($data));
    $panel->content($self->content($data, $container));
  };
}

sub subtitle {
  my ($self, $data) = @_;

  return sprintf("%d matches, %d generated", scalar $data->{matched}->@*, scalar $data->{generated}->@*);
}

sub content {
  my ($self, $data, $container) = @_;
  my  $html = <<'HTML';
  <h3>Matched routes</h3>
<table><thead><tr><th>Route</th><th>Method</th><th>Pattern</th><th>Controller</th><th>Match</th></tr></thead><tbody>
HTML

  my $i = 0;
  foreach my $route ($data->{matched}->@*) {
    my $class = $i++ % 2 == 0 ? 'plDebugOdd' : 'plDebugEven';
    $html .= "<tr class=\"${class}\">";
    $html .= sprintf('<td>%s</td>', encode_entities($route->{name}));
    $html .= sprintf('<td>%s</td>', encode_entities(join(', ', @{$route->{method}})));
    $html .= sprintf('<td>%s</td>', encode_entities($route->{pattern}));
    $html .= sprintf('<td>%s->%s</td>', encode_entities($route->{dest}->{controller}), encode_entities($route->{dest}->{action}));
    $html .= sprintf('<td><pre>%s</pre></td>', encode_entities($container->yaml()->dump($route->{match})));
    $html .= '</tr>';
  }
  $html .= '</tbody></table>';

  $html .= <<'HTML';
  <h3>Generated routes</h3>
<table><thead><tr><th>Route</th><th>Path</th><th>Pattern</th><th>Args</th></tr></thead><tbody>
HTML

  $i = 0;
  foreach my $route ($data->{generated}->@*) {
    my $class = $i++ % 2 == 0 ? 'plDebugOdd' : 'plDebugEven';
    $html .= "<tr class=\"${class}\">";
    $html .= sprintf('<td>%s</td>', encode_entities($route->{name}));
    $html .= sprintf('<td>%s</td>', encode_entities($route->{path}));
    $html .= sprintf('<td>%s</td>', encode_entities($route->{pattern}));
    $html .= sprintf('<td>%s</td>', encode_entities($container->yaml()->dump($route->{args})));
    $html .= '</tr>';
  }
  $html .= '</tbody></table>';

  return $html;
}

1;
