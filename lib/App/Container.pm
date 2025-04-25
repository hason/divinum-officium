use v5.38;
use strict;
use feature 'class';
use warnings qw(all -experimental::class);

use App::Router;
use FindBin;
use Plack::Request;
use Template;
use YAML::PP;

class App::Container {
  field $env : param;
  field $psgi : param;

  field $request;
  field $router;
  field $template;
  field $controller_factory;
  field $yaml;

  ADJUST {
    $psgi->{'container'} = $self if defined $psgi;
    print $psgi->{'container'};
  }

  method yaml() {
    return $yaml //= YAML::PP->new(preserve => YAML::PP::Common::PRESERVE_ORDER, header => 0);
  }

  method request() {
    return $request //= Plack::Request->new($psgi);
  }

  method router() {
    return $router //= App::Router->new(
      base => $self->request()->base,
      routes => $self->yaml()->load_file("$FindBin::Bin/config/routes.yaml")->{routes},
    );
  }

  method template() {
    use App::Debug::TemplateContext;
    $Template::Config::CONTEXT = 'App::Debug::TemplateContext';

    return $template //= Template->new(
      {
        INCLUDE_PATH => "$FindBin::Bin/templates",
        ENCODING => 'utf8',
        VARIABLES => {
          path_for => sub ($name, $params = {}) { $self->router()->path_for($name, $params) },
          url_for => sub ($name, $params = {}) { $self->router()->url_for($name, $params) },
          sprintf => sub ($format, @args) { sprintf($format, @args) },
        },
      }
    );
  }

  method controller_factory() {
    return $controller_factory //= sub ($class, $request, $route) {
      return $class->new(
        route => $route,
        request => $request,
        di => $self,
      );
    };
  }
}
