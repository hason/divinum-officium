use v5.38;
use strict;
use feature 'class';
use warnings qw(all -experimental::class);

use Plack::Builder;
use Plack::Request;
use Plack::Middleware::Static;
use FindBin;
use App::Container;

class App::Web {
  field $env : param;
  field $container;

  ADJUST {
    $env //= 'production';
  }

  # method call($env) {
  #   my $path = $env->{PATH_INFO};
  #
  #   for my $r (@static_routes) {
  #     my $prefix = $r->{path};
  #     my $regex = $prefix eq '*' ? qr{.*} : qr{^$prefix};
  #     if ($path =~ $regex) {
  #       my $rel_path = $path;
  #       $rel_path =~ s{^$prefix}{};
  #       my $file_path = $r->{root} . $rel_path;
  #       return $self->serve_static($file_path);
  #     }
  #   }
  #
  #   my ($route, $params) = $router->match($env);
  #   if ($route) {
  #     $env->{'app.route.controller'} = $route->{controller};
  #     $env->{'app.route.action'}     = $route->{action};
  #     $env->{'app.route.params'}     = $params;
  #     return $self->app->($env);
  #   }
  #
  #   return [404, ['Content-Type' => ['text/plain']], ['Not Found']];
  # }

  method test() {

    # my $app = sub ($env) {
    #   my $controller_class = $env->{'app.route.controller'}
    #     or return [404, ['Content-Type' => ['text/plain']], ['Not found']];
    #
    #   my $action = $env->{'app.route.action'} // 'index';
    #   my $params = $env->{'app.route.params'} // {};
    #   my $req = Plack::Request->new($env);
    #
    #   eval "require $controller_class" or return [500, ['Content-Type' => ['text/plain']], ["Can't load controller: $@"]];
    #
    #   my $factory = $container->resolve('controller_factory');
    #   my $controller = $factory->($controller_class, $req, $env->{PATH_INFO});
    #   my $res = $controller->$action($params);
    #
    #   return $res->finalize;
    # };
  }

  method app ($psgi) {
    $container = App::Container->new(
      env => $env,
      psgi => $psgi
    );
    my $req = $container->request();

    my $router = $container->router();
    my $data = $router->match($psgi);
    return [404, ['Content-Type' => ['text/plain']], ['Not found']] unless $data;

    eval "require $data->{controller}" or die $@;

    my $factory = $container->controller_factory();
    my $controller = $factory->($data->{controller}, $req, $data->{route});
    my $method = $data->{action};
    my $params = $data->{params} // {};
    my $response = $controller->$method($params);

    return $response->finalize;
  }

  method to_psgi () {
    return Plack::Builder::builder {
      Plack::Builder::enable('ContentLength');

      if ($env eq 'development') {
        Plack::Builder::enable(
          'Debug',
          panels => [
            'Environment', 'Parameters', 'Response', 'Timer',
            'Memory', 'PerlConfig', '+App::Debug::DumperPanel', '+App::Debug::TemplatePanel',
            , '+App::Debug::RouterPanel',
          ],
        );
        Plack::Builder::enable('StackTrace');
        Plack::Builder::enable('Lint');
      }

      sub ($psgi) { $self->app($psgi) };
    };
  }
}
