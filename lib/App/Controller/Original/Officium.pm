package App::Controller::Original::Mobile;

use v5.38;
use strict;
use warnings;
use feature 'class';

class App::Controller::Original::Officium : isa(App::BaseController) {

  method index(@) {
    use DivinumOfficium::Globals;
    use DivinumOfficium::DialogCommon qw(getini set_runtime_options);

    getini('horas');
    loadsetup($setupsave);

    $self->template(
      'original/horas/mobile/calendar.html.tt', {

      },
    );
  }

  method mobile(@) {

  }

  method options(@) {

  }
}

