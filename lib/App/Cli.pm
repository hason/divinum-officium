use v5.38;
use strict;
use feature 'class';
use warnings qw(all -experimental::class);

use App::Cmd;
use App::Container;

class App::Cli {
  field $env : param;
  field $container;
  field $cmd;

  ADJUST {
    $env //= 'production';
    $container = App::Container->new(
      env => $env,
      psgi => undef,
    );
    $cmd = App::Cmd->new(
      {
        description => 'Divinum Officium CLI',
        command_namespace => 'App::Command',
        no_command_namespace => 1,
      }
    );

    $self->add_command(App::Command::Hello);
  }

  method run(@args) {
    return $cmd->run(@args);
  }

  method add_command($command) {
    $cmd->_register_command($command);
  }
}
