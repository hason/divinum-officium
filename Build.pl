#!/usr/bin/perl

use strict;
use warnings;

use lib 'web/cgi-bin';
use Module::Build;

my $build = Module::Build->new(
  module_name => 'DivinumOfficium',
  dist_version => 0,
  dist_author => 'Divinum Officium',
  dist_abstract => 'Generates texts for the traditional Roman liturgy.',
  requires => {
    'perl' => '5.40',
    'Bread::Board' => 0,
    'CGI' => 0,
    'CGI::Carp' => 0,
    'CGI::Cookie' => 0,
    'Encode' => 0,
    'File::Basename' => 0,
    'FindBin' => 0,
    'Plack' => 0,
    'Time::Local' => 0,
    'Template' => 0,
    'Test::Cmd' => 0,
    'Test::Carp' => 0,
    'DateTime' => 0,
    'List::MoreUtils' => 0,
    'URI::Router' => 0,
  },
  build_requires => {
    'Perl::Tidy' => 0,
    'Perl::Critic' => 0,
  },
);

$build->create_build_script();
