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
    my $xpf = XPathFeed->new_from_query($c->req);
    return $c->render(
        index => {
            xpf => $xpf,
        }
    );
};

get '/frame' => sub {
    my ($c) = @_;
    my $xpf = XPathFeed->new_from_query($c->req);
    return $c->create_response(
        200,
        [
            'Content-Type'    => 'text/html',
            'X-Frame-Options' => 'SAMEORIGIN',
        ],
        [$xpf->frame_content],
    );

};

get '/feed' => sub {
    my ($c) = @_;
    my $xpf = XPathFeed->new_from_query($c->req);
    return $c->create_response(
        200,
        [
            'Content-Type'    => 'text/xml',
        ],
        [$xpf->feed],
    );

};

builder {
    enable 'Plack::Middleware::Static',
        path => qr{^/(?:images|css|js)/},
        root => $root->subdir('static');

    enable 'Plack::Middleware::ReverseProxy';

    __PACKAGE__->to_app(
        no_x_frame_options => 1,
    );
};

__DATA__
@@ index
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>XPathFeed</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="/css/bootstrap.css" rel="stylesheet">
    <link href="/css/flat-ui.css" rel="stylesheet">
    <link href="/css/xpathfeed.css" rel="stylesheet">
    <!-- link rel="shortcut icon" href="images/favicon.ico" -->
    <!--[if lt IE 9]>
      <script src="js/html5shiv.js"></script>
    <![endif]-->
  </head>
  <body>
    <div class="container">
      <div class="headline">
        <h1 class="title-logo">XPathFeed</h1>
        <p>Generate RSS Feed from XPath</p>
      </div>
      <div class="row">
        <form action="./" method="get">

          <h2>[% UNLESS xpf.url %]Enter [% END %]URL</h2>
          <input type="text" name="url" value="[% xpf.url %]" placeholder="URL">
          [% IF xpf.url %]

            <h2>Preview of <a href="[% xpf.url %]">[% xpf.title %]</a></h2>
            <iframe id="iframe" frameborder="0"></iframe>
            <script>
              setTimeout( function(){
                document.getElementById('iframe').src = '/frame?url=[% xpf.url | uri %]'
              } , 10 );
            </script>

            <h2>[% UNLESS xpf.xpath_list %]Enter [% END %]XPath</h2>

            <input type="text" name="xpath_list" value="[% xpf.xpath_list %]" placeholder="XPath or CSS Selector">

            [% IF xpf.list_size %]

              <h2>List <span style="font-size:80%">([% xpf.list_size %] items)</span></h2>

              [% FOREACH item IN xpf.list %]
                [% LAST IF loop.count > 5 %]
                <div class="row mbl">
                  <div class="span4 palette palette-silver">
                    <p>[% item.title %]</p>
                    <p>[% item.link %]</p>
                  </div>
                  <div class="span8 palette palette-clouds"><pre class="source">[% item.html %]</pre></div>
                </div>[% # div.row %]
              [% END # FOREACH item IN xpf.list %]

              <div class="row">
                <a href="[% xpf.feed_url %]" class="btn btn-large btn-block palette palette-bright-dark">RSS Feed Here!!</a>
              </div>

            [% ELSE # IF xpf.list_size %]

              <input type="submit" value="Next Step" class="btn">

            [% END # IF xpf.list_size %]

          [% ELSE # IF xpf.url %]

            <input type="submit" value="Next Step" class="btn">

          [% END # IF xpf.url %]
        </form>
      </div>[% # div.row %]
    </div>[% # div.container %]

    <footer>
      <div class="container">
        <div class="row">
          <div class="span12" style="text-align:center">
          <p class="mtl mbl">&copy; <a href="http://www.hatena.ne.jp/">id:onishi</a></p>
          </div>
        </div>
      </div>
    </footer>

  </body>
</html>
