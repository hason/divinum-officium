use v5.38;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use App::Web;

my $app = App::Web->new(env => $ENV{PLACK_ENV} // 'production')->to_psgi();
