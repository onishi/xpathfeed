package Test::XPathFeed;
use strict;
use warnings;
use base qw/Test::Class/;

use Test::More;
use Encode 'decode_utf8';
use XPathFeed;

BEGIN {
    no strict 'refs';
    require Cache::FileCache;
    local *Cache::FileCache::get = sub {};
    local *Cache::FileCache::set = sub {};
};

sub _compile : Test(1) {
    use_ok('XPathFeed');
}

sub _new : Test(4) {
    my $self = shift;
    my $xpf1 = XPathFeed->new;
    ok $xpf1, 'new';

    my $xpf2 = XPathFeed->new(
        url => 'hoge'
    );
    is $xpf2->url, 'hoge', 'hash';

    my $xpf3 = XPathFeed->new({
        url => 'hoge'
    });
    is $xpf3->url, 'hoge', 'hashref';

    require CGI;
    my $xpf4 = XPathFeed->new_from_query(
        CGI->new('url=hoge')
    );
    is $xpf4->url, 'hoge', 'new_from_query';
}

sub _ua : Test(1) {
    my $self = shift;
    my $xpf = XPathFeed->new;
    my $ua  = $xpf->ua;
    isa_ok($ua, "XPathFeed::UserAgent");
}

sub _cache : Test(1) {
    my $self = shift;
    my $xpf = XPathFeed->new;
    my $cache  = $xpf->cache;
    isa_ok($cache, "Cache::FileCache");
}

sub _http_result : Test(6) {
    my $self = shift;
    require Encode;
    no warnings 'redefine';
    local *LWP::UserAgent::request = sub {
        return HTTP::Response->new(
            200,
            'OK',
            HTTP::Headers->new(Content_Type => 'text/html; charset=utf-8'),
            '<html><body><a href="./hoge">ほげ</a></body></html>'
        );
    };
    my $xpf = XPathFeed->new(
        url => 'http://hogehoge.com/_http_result',
    );
    my $result = $xpf->http_result;

    is $result->{content}, '<html><body><a href="./hoge">ほげ</a></body></html>';
    is $xpf->content,      '<html><body><a href="./hoge">ほげ</a></body></html>';

    is $result->{resolved_content}, '<html><body><a href="http://hogehoge.com/hoge">ほげ</a></body></html>';
    is $xpf->resolved_content,      '<html><body><a href="http://hogehoge.com/hoge">ほげ</a></body></html>';

    is $result->{decoded_content}, decode_utf8('<html><body><a href="./hoge">ほげ</a></body></html>');
    is $xpf->decoded_content,      decode_utf8('<html><body><a href="./hoge">ほげ</a></body></html>');

    $xpf->clean;
}

sub _tree : Tests { local $TODO = 'TODO' }

sub _list : Test(5) {
    my $self = shift;

    no warnings 'redefine';
    local *LWP::UserAgent::request = sub {
        return HTTP::Response->new(
            200,
            'OK',
            HTTP::Headers->new(Content_Type => 'text/html; charset=utf-8'),
            '<html><head></head><body><ul><li><a href="./hoge">ほげ</a></li><li><a href="./fuga">ふが</a></li></ul></body></html>'
        );
    };

    my $xpf = XPathFeed->new(
        url        => 'http://hogehoge.com/_list',
        xpath_list => 'ul li',
    );
    my $list = $xpf->list;
    is $list->[0]->{node}->as_XML_compact,
        decode_utf8('<li><a href="./hoge">ほげ</a></li>');
    is $list->[0]->{title}, decode_utf8('ほげ');
    is $list->[0]->{link}, decode_utf8('http://hogehoge.com/hoge');

    is $list->[1]->{node}->as_XML_compact,
        decode_utf8('<li><a href="./fuga">ふが</a></li>');
    is $list->[1]->{link}, decode_utf8('http://hogehoge.com/fuga');

    $xpf->clean;
}

sub _search : Test(3) {
    my $self = shift;
    no warnings 'redefine';
    local *LWP::UserAgent::request = sub {
        return HTTP::Response->new(
            200,
            'OK',
            HTTP::Headers->new(Content_Type => 'text/html; charset=utf-8'),
            '<html><head></head><body><ul><li><a href="./hoge">ほげ</a></li><li><a href="./fuga">ふが</a></li></ul></body></html>'
        );
    };

    my $xpf = XPathFeed->new(
        url         => 'http://hogehoge.com/_list',
        search_word => 'ほげ',
    );
    my $result = $xpf->search;
    ok $result;
    is ref $result, 'ARRAY';
    is scalar @$result, 1;

}

__PACKAGE__->runtests;

1;
