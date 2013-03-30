use strict;
use warnings;

use Path::Class;
my $root = dir(__FILE__)->parent;

use Plack::Builder;

use lib 'lib';
use XPathFeed;

use Amon2::Lite;

get '/' => sub {
    my ($c) = @_;
    return $c->render('index.tt');
};


builder {
    enable 'Plack::Middleware::Static',
        path => qr{^/(?:images|css|js)/},
        root => $root->subdir('static');

    enable 'Plack::Middleware::ReverseProxy';

    __PACKAGE__->to_app();
};

__DATA__
@@ wrapper.tt
<!DOCTYPE html>
<html>
<body>
[% content %]
</body>
</html>

@@ index.tt
[% WRAPPER "wrapper.tt" %]
index w/wrapper
[% END %]
