package App::Debug::TemplatePanel;

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
      $data = $container->template()->context()->processed_templates();
    }
    $panel->title('Templates');
    $panel->nav_title('Templates');
    $panel->nav_subtitle($self->subtitle($data));
    $panel->content($self->content($data));
  };
}

sub subtitle {
  my ($self, $nodes) = @_;
  return sprintf("%d templates", $self->_count_templates($nodes));
}

sub _count_templates {
  my ($self, $nodes) = @_;
  return 0 unless $nodes && @$nodes;

  my $count = 0;

  foreach my $node (@$nodes) {
    $count += ($node->{type} && $node->{type} eq 'template') ? 1 : 0;
    $count += $self->_count_templates($node->{children});
  }

  return $count;
}

sub content {
  my ($self, $nodes) = @_;

  my $html = <<'HTML';
<style>
  #plDebug ul.tt-tree {
    padding-left: 1.5em;
    list-style-type: disc;
  }
  #plDebug ul.tt-tree li {
    margin-bottom: 0.2em;
  }
</style>
<ul class="tt-tree">
HTML

  $html .= $self->_tree_to_list($nodes);

  return $html;
}

sub _tree_to_list {
  my ($self, $nodes) = @_;
  return '' unless $nodes && @$nodes;

  my $html = '';
  foreach my $node (@$nodes) {
    my $label = encode_entities($node->{name});
    $label .= sprintf(" [%s]", $node->{type}) if $node->{type};
    $label .= sprintf(" (%d×, %d ms)", $node->{count}, $node->{duration_ms} // 0);

    $html .= '<li>' . $label;
    $html .= $self->content($node->{children});
    $html .= '</li>';
  }
  $html .= '</ul>';

  return $html;
}

1;
