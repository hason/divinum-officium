package App::Debug::TemplateContext;

use strict;
use warnings;
use parent 'Template::Context';
use Time::HiRes qw(time);

sub new {
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);

  $self->{_stack} = [];
  $self->{_tree} = [];
  $self->{_counter} = {};
  $self->{_last_template_name} = undef;

  return $self;
}

sub template {
  my ($self, $name) = @_;

  $self->{_last_template_name} = $name if defined $name;

  return $self->SUPER::template($name);
}

sub process {
  my ($self, @args) = @_;
  my ($template) = @args;

  my $name;
  my $type;

  if (ref($template) eq 'Template::Document') {
    $name = $template->{_NAME} || $self->{_last_template_name} || "$template";
    $type = 'template';
  } elsif (!ref($template) && $template =~ /\.\w+\.?tt2?$/) {
    $name = $template;
    $type = 'template';
  } elsif (!ref($template)) {
    $name = $template;
    $type = 'block';
  } else {
    $name = "$template";
    $type = 'unknown';
  }

  $self->{_counter}{$name}++;

  my $node = {
    name => $name,
    type => $type,
    count => $self->{_counter}{$name},
    children => [],
  };

  if (@{$self->{_stack}}) {
    push @{$self->{_stack}[-1]{children}}, $node;
  } else {
    push @{$self->{_tree}}, $node;
  }

  my $start = time;
  push @{$self->{_stack}}, $node;

  my $result = $self->SUPER::process(@args);

  pop @{$self->{_stack}};
  my $end = time;

  $node->{duration_ms} = int(1000 * ($end - $start));

  return $result;
}

sub processed_templates {
  my ($self) = @_;
  return $self->{_tree};
}

1;
