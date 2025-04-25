use v5.38;
use feature 'class';

class App::Controller::Missa : isa(App::BaseController) {

  method show () {
    my $name = $req->cookies->{name} // '';
    return $self->tt(
      'missa.tt', {
        title => 'Missa',
        name => $name,
        has_cookie => $name ne '',
      },
    );
  }

  method submit () {
    my $name = $req->body_parameters->get('name') // '';
    my $res = $self->tt(
      'missa.tt', {
        title => 'Výsledek',
        name => $name,
      },
    );

    $res->cookies->{name} = {
      value => $name,
      path => '/',
      expires => time + 60 * 60 * 24 * 30,
    };

    return $res;
  }
}
