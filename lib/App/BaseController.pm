use v5.38;
use strict;
use feature 'class';
use warnings qw(all -experimental::class);

use Plack::Response;

class App::BaseController {
  use Encode qw(encode);
  use Scalar::Util qw(openhandle);

  field $request : param;
  field $route : param;
  field $di : param;

  method request () {
    return $request;
  }

  method dump(@args) {
    App::Debug::DumperPanel::dump(@args);
  }

  method param($name, $default = undef) {
    return $request->param($name) // $default;
  }

  method template ($template, $vars = {}) {
    my $tt = $di->template();
    my $out = '';
    my $success = $tt->process(
      $template, {
        %$vars,
        request => $request,
        route => $route,
        controller => $self,
      },
      \$out,
    );

    if (!$success) {
      die $tt->error();
    }

    return $self->response(200, $out);
  }

  method redirect ($location, $status = 302) {
    my $res = Plack::Response->new($status);
    $res->redirect($location);
    return $res;
  }

  method response ($code, $body, $type = 'text/html; charset=utf-8') {
    my $res = Plack::Response->new($code);

    if ($type =~ m{^(text/[^ ;]+|application/(json|javascript|xml|x-www-form-urlencoded))$}) {
      $type = "$type; charset=utf-8";
    }

    $res->content_type($type);
    $res->body(openhandle($body) ? $body : encode('UTF-8', $body));
    return $res;
  }
}
