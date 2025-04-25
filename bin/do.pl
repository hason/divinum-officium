#!/usr/bin/env perl
use v5.38;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../web/lib";

use App::Cli;

exit App::Cli->new(env => 'production')->run;
