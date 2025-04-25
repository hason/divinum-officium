use v5.38;
use feature 'class';

class App::Controller::Legacy : isa(App::BaseController) {

  method redirect_old_url () {
    return $self->redirect($router->url_for('missa_show'), 301);
  }
}
