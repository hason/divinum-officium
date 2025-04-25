use v5.38;
use strict;
use feature 'class';
use warnings qw(all -experimental::class);

use File::Spec;
use FindBin;
use Plack::MIME;
use Plack::Response;

class App::Controller::Static : isa(App::BaseController) {

  method serve ($params) {
    my $file = File::Spec->catfile("$FindBin::Bin/$params->{root}", $params->{file} // $params->{asset});
    return $self->response(404, 'Not found', 'text/plain') unless -f "$file";

    open my $fh, '<', $file or return $self->response(500, 'Cannot open', 'text/plain');
    binmode $fh;

    my $type = Plack::MIME->mime_type($file) || 'application/octet-stream';

    return $self->response(200, $fh, $type);
  }
}
