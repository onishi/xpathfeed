package XPathFeed;
use strict;
use warnings;
use base qw/Class::Accessor::Fast Class::Data::Inheritable/;

use XPathFeed::UserAgent;

use Cache::FileCache;
use Encode qw(decode_utf8);
use HTML::ResolveLink;
use HTML::Selector::XPath;
use HTML::Tagset;
use HTML::TreeBuilder::XPath;
use HTTP::Request;
use Scalar::Util qw(blessed);
use URI;
use URI::Escape qw(uri_escape);
use XML::RSS;

our ($UserAgent, $Cache);

our $EXPIRE = 10 * 60; # 10分

our $DEFAULT_XPATH_ITEM = {
    title       => '//a',
    link        => '//a/@href',
    image       => '//img/@src',
    description => '//*',
};

__PACKAGE__->mk_classdata(
    params => [
        qw{
            url
            search_word
            xpath_list
            xpath_item_title
            xpath_item_link
            xpath_item_image
            xpath_item_description
        },
    ],
);

__PACKAGE__->mk_accessors(
    @{__PACKAGE__->params},
    qw{
        error
        create
    },
);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    return $class->SUPER::new({%args});
}

sub new_from_query {
    my ($class, $q) = @_;
    $class->new(
        map {
            $_ => $q->param($_) || '',
        } @{$class->params},
    );
}

sub ua {
    $UserAgent ||= XPathFeed::UserAgent->new;
}

sub cache {
    $Cache ||= Cache::FileCache->new(
        {
            namespace  => 'xpathfeed',
            cache_root => '/tmp/filecache',
        }
    );
}

sub resolver {
    my $self = shift;
    $self->{resolver} ||= HTML::ResolveLink->new(
        base => $self->url,
    );
}

sub uri {
    my $self = shift;
    my $url = $self->url;
    $url =~ /http/ or $url = "http://$url";
    $self->{uri} ||= URI->new($url)->canonical;
}

sub http_result {
    my $self = shift;
    $self->{http_result} ||= do {
        my $url    = $self->uri;
        my $cache  = $self->cache;
        my $result = $cache->get($url);
        if (!$result) {
            # キャッシュがない場合
            my $res = $self->_get($url);
            if ($res->is_success) {
                $result = $self->_res2result($res);
                $cache->set($url, $result);
            }
        } elsif (my $now = time() - $result->{cached} > $EXPIRE) {
            # キャッシュがexpireしている場合
            my $res = $self->_get($url, $now);
            if ($res->code == 304) {
                $result->{cached} = $now; # 時間だけ上書き
                $cache->set($url, $result);
            } elsif ($res->is_success) {
                $result = $self->_res2result($res);
                $cache->set($url, $result);
            }
        }
        $result || {};
    }
}

sub _get {
    my $self = shift;
    my $url  = shift;
    my $time = shift; # If-Modified-Since
    my $req = HTTP::Request->new('GET', $url);
       $req->if_modified_since($time) if $time;
    return $self->ua->request($req);
}

sub _res2result {
    my ($self, $res) = @_;
    return {
        content          => $res->content,
        resolved_content => $self->_resolve($res->decoded_content),
        decoded_content  => $res->decoded_content,
        cached           => time(),
    };
}

sub _resolve {
    my $self = shift;
    my $content = shift or return;
    $content = Encode::encode('utf-8', $content) if Encode::is_utf8($content);
    $content = $self->resolver->resolve($content);
    $content;
}

sub _add_inspector {
    my $content = shift;
    $content =~ s{<base [^>]+>}{}ig;
    my $script = '<script type="text/javascript" charset="utf-8" src="/js/inspector.js"></script>';
    $content =~ s{(</body>)}{$script$1} or $content .= $script;
    $content;
}

sub frame_content {
    my $self = shift;
    $self->{frame_content} ||= _add_inspector($self->resolved_content);
}

BEGIN {
    no strict 'refs';
    for my $method (qw/content resolved_content decoded_content/) {
        *{__PACKAGE__.'::'.$method} = sub {
            my $self = shift;
            $self->{$method} = shift || $self->http_result->{$method} || '';
        }
    }
}

sub tree {
    my $self = shift;
    return $self->{tree} if exists $self->{tree};
    $self->{tree} = do {
        my $t = HTML::TreeBuilder::XPath->new;
        $t->parse($self->decoded_content);
        $t->eof;
        $t;
    } || undef;
}

sub list {
    my $self = shift;
    return $self->{list} if defined $self->{list};
    my $class = ref $self;
    my $list = eval {
        local $SIG{__WARN__} = sub { };
        my @nodes = $self->tree->findnodes(xpath($self->xpath_list));
        [map { {node => $_} } @nodes];
    } || [];
    for my $item (@$list) {
        $item or next;
        my $node = $item->{node} or next;
        my $tree = $node->clone or next; # この要素以下のtreeにする
        for my $key (sort keys %$DEFAULT_XPATH_ITEM) {
            my $method = 'xpath_item_' . $key;
            my $xpath = $self->$method() || $DEFAULT_XPATH_ITEM->{$key} or next;
            $item->{$key} = eval {
                local $SIG{__WARN__} = sub { };
                my @nodes = $tree->findnodes(xpath($xpath));
                extract($nodes[0], $key, $self->uri);
            };
            $item->{html} = $node->as_XML;
        }
        push @{$self->{list}}, $item;
        $tree->delete;
    }
    $self->{list};
}

sub list_size {
    my $self = shift;
    return scalar @{$self->list || []};
}

sub title {
    my $self = shift;
    $self->{title} // eval {
        local $SIG{__WARN__} = sub { };
        my ($node) = $self->tree->findnodes(xpath('title'));
        my $title = $node ? $node->as_text || '' : '';
        $title =~ s{\s+}{ }g;
        $title =~ s{(?:^\s|\s$)}{}g;
        $title;
    } || $self->url || '';
}

sub search {
    my $self = shift;
    return $self->{search_result} if defined $self->{search_result};
    my $word = $self->search_word or return;
       $word =~ s{'}{\\'}g;
    my $xpath = xpath(sprintf(q{//text()[contains(.,'%s')]/..}, $word));
    $self->{search_result} = do {
        local $SIG{__WARN__} = sub { };
        my @nodes = $self->tree->findnodes($xpath);
        [map { {node => $_} } @nodes];
    } || [];
    return $self->{search_result};
}

sub feed {
    my $self = shift;
    my $list = $self->list;
    $self->{feed} ||= do {
        my $rss = XML::RSS->new (version => '2.0');
        $rss->channel(
            title       => $self->title,
            link        => $self->page_uri,
            description => $self->url,
        );
        for my $item (@$list) {
            $rss->add_item(
                title       => $item->{title},
                link        => $item->{link},
                description => $item->{description},
                enclosure   => $item->{image} ? {
                    url  => $item->{image},
                    type => "image"
                } : undef,
            );
        }
        $rss->as_string;
    };
}

sub page_uri { shift->add_query_params(URI->new('/')) }
sub feed_uri { shift->add_query_params(URI->new('/feed')) }

sub add_query_params {
    my $self = shift;
    my $uri = shift or return;
    for my $key (qw/url xpath_list xpath_item_title xpath_item_link xpath_item_image xpath_item_description/) {
        $self->$key() or next;
        $uri->query_form(
            $uri->query_form,
            $key => $self->$key(),
        );
    }
    return $uri;
}

sub clean {
    my $self = shift;
    $self->tree or return;
    $self->tree->delete;
}

sub DESTROY {
    my $self = shift;
    $self->clean;
}

# utility method

sub xpath {
    # xpath || css selector を xpath に変換する
    # copy from Web::Scraper
    my $exp = shift;
    my $xpath = $exp =~ m!^(?:/|id\()! ? $exp : HTML::Selector::XPath::selector_to_xpath($exp);
    decode_utf8($xpath);
}

sub extract {
    my ($node, $key, $uri) = @_;
    if (blessed($node) && $node->isa('HTML::TreeBuilder::XPath::Attribute')) {
        if (is_link_element($node->getParentNode, $node->getName)) {
            URI->new_abs($node->getValue, $uri);
        } else {
            $node->getValue;
        }
    } elsif (blessed($node) && $node->can('as_text')) {
        $node->as_text;
    }
}

sub is_link_element {
    my($node, $attr) = @_;
    my $link_elements = $HTML::Tagset::linkElements{$node->tag} || [];
    for my $elem (@$link_elements) {
        return 1 if $attr eq $elem;
    }
    return;
}

1;

__END__

=head1 NAME

XPathFeed - Generate RSS Feed from XPath

=head1 SYNOPSIS

  use XPathFeed;
  my $x = XPathFeed->new;
  $x->url($url);
  $x->xpath_list($xpath);
  print $x->feed;

=head1 DESCRIPTION

XPathFeed is a feed generator from xpath.

  use XPathFeed;
  my $x = XPathFeed->new;
  $x->url($url);
  $x->xpath_list($xpath);
  print $x->feed;

  or

  plackup app.psgi

=over

=item new

=item new_from_query

=item url

=item xpath_list

=item xpath_item_title

=item xpath_item_link

=item xpath_item_image

=item xpath_item_description

=item list

=item feed

=back

=head1 AUTHOR

Yasuhiro Onishi E<lt>yasuhiro.onishi@gmail.comE<gt>

=head1 SEE ALSO

=over

=item L<Web::Scraper>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
