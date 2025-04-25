use v5.38;
use strict;
use feature 'class';
use warnings qw(all -experimental::class);

class App::Controller::Original::Pages : isa(App::BaseController) {

  method index (@) {
    $self->template('original/index.html.tt');
  }

  method help ($params) {
    $self->template("original/help/$params->{page}.html.tt");
  }
}
