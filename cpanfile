requires 'perl', '5.038';

requires 'App::Cmd';
requires 'Plack';
requires 'Router::Simple';
requires 'Template';
requires 'Starman';
requires 'YAML::PP';

on 'develop' => sub {
    requires 'Data::Dumper';
    requires 'Perl::Tidy';
    requires 'Perl::Critic';
    requires 'Plack::Middleware::Debug';
};
