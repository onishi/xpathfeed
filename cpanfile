requires 'Cache::FileCache';
requires 'Class::Accessor::Fast';
requires 'Class::Data::Inheritable';
requires 'Encode';
requires 'HTML::ResolveLink';
requires 'HTML::Selector::XPath';
requires 'HTML::Tagset';
requires 'HTML::TreeBuilder::XPath';
requires 'HTTP::Request';
requires 'LWP::UserAgent';
requires 'Scalar::Util';
requires 'URI';
requires 'URI::Escape';
requires 'XML::RSS';

on test => sub {
    requires 'Test::Class';
    requires 'Test::More', 0.98;
};

on configure => sub {
};

on 'develop' => sub {
};

feature 'psgi', 'web app support' => sub {
    requires 'Plack';
    requires 'Path::Class';
    requires 'Amon2::Lite';
    requires 'Plack::Middleware::AccessLog::Timed';
    requires 'Plack::Middleware::ReverseProxy';
};
