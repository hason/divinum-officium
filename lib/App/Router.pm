use v5.38;
use feature 'class';
use warnings qw(all -experimental::class);

use Router::Simple;

class App::Router {
  field $base : param;
  field $routes : param;

  field $router;
  field $processed_routes;

  ADJUST {
    $base =~ s{/$}{};
    $router = Router::Simple->new;
    $processed_routes = {
      matched => [],
      generated => [],
    };

    for my $name (keys %$routes) {
      my $r = $routes->{$name};
      my $destination;

      if ($r->{root}) {
        $destination = {
          controller => 'App::Controller::Static',
          action => 'serve',
          root => $r->{root}
        };
      } else {
        $destination = {
          controller => $r->{controller},
          action => $r->{action}
        };
      }
      $router->connect($name, $r->{path}, $destination, {method => $r->{method} // 'GET'});
    }
  }

  method match ($envOrPath) {
    my ($match, $route) = $self->_match($envOrPath);

    if (!defined $route) {
      return;
    }

    delete $match->{controller};
    delete $match->{action};

    return {
      name => $route->name,
      controller => $route->dest->{controller},
      action => $route->dest->{action},
      params => $match,
      route => $route,
    };
  }

  method path_for($name, $args = {}) {
    foreach my $route (@{$router->routes}) {
      if ($route->name eq $name) {
        my $splat_index = 0;
        my $path = $route->pattern;
        my %used_args;

        $path =~ s!
                  \{((?:\{[0-9,]+\}|[^{}]+)+)\} | # /blog/{year:\d{4}}
                  :([A-Za-z0-9_]+)              | # /blog/:year
                  (\*)                          | # /blog/*/*
                  ([^{:*]+)                       # normal string
              !
                if ($1) {
                  my ($name) = split /:/, $1, 2;
                  $used_args{$name} = 1;
                  defined $args->{$name} ? $args->{$name} : '';
                }
                elsif ($2) {
                  $used_args{$2} = 1;
                  $args->{$2};
                }
                elsif ($3) {
                  $used_args{splat} = 1;
                  $args->{splat}->[$splat_index++];
                }
                else {
                  $4;
                }
              !gex;

        my %leftover = %$args;
        delete @leftover{ keys %used_args };

        my $query = '';
        if (%leftover) {
          use URI::Escape qw(uri_escape);
          my @pairs;
          for my $k (sort keys %leftover) {
            my $v = $leftover{$k};
            $v = join(',', @$v) if ref $v eq 'ARRAY';
            push @pairs, uri_escape($k) . '=' . uri_escape($v);
          }
          $query = '?' . join('&', @pairs) if @pairs;
        }

        my $full_path = $path . $query;

        push @{$processed_routes->{generated}}, {
          name => $name,
          pattern => $route->pattern,
          path => $full_path,
          args => $args,
        };

        return $full_path;
      }
    }

    push @{$processed_routes->{generated}}, {
      name => $name,
      pattern => undef,
      path => undef,
      args => $args,
    };

    return;
  }

  method url_for($name, $args = {}) {
    my $path = $self->path_for($name, $args);
    $processed_routes->{generated}[-1]{path} = $base . $processed_routes->{generated}[-1]{path};

    return "$base$path";
  }

  method processed_routes() {
    return $processed_routes;
  }

  method _match($env) {
    if (ref $env) {
      if ($env->{PATH_INFO} eq '') {
        $env->{PATH_INFO} = '/';
      }
    } else {
      $env = +{ PATH_INFO => $env }
    }

    $router->{method_not_allowed} = 0;
    for my $route (@{$router->routes}) {
      my $match = $route->match($env);
      push @{$processed_routes->{matched}}, {
        name     => $route->name,
        pattern  => $route->pattern,
        match    => $match,
        dest => $route->dest,
        method   => $route->method,
      };

      if ($match) {
        return ($match, $route);
      }
    }
    $router->{method_not_allowed} = $Router::Simple::_METHOD_NOT_ALLOWED;
    return undef;
  }
}
