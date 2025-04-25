use v5.38;
use strict;
use features 'class';
use warnings qw(all -experimental::class);

class App::Command::Hello {
  method name {'hello'}
  method description {'Řekne ahoj'}

  method opt_spec {
    return (['name=s', 'Jméno, které se má pozdravit']);
  }

  method execute($opt, $args) {
    my $name = $opt->{name} // 'světe';
    say "Ahoj, $name!";
  }
}
