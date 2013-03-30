package Test::XPathFeed::UserAgent;
use strict;
use warnings;
use base qw/Test::Class/;

use Test::More;
use XPathFeed::UserAgent;

sub _00_compile : Test(2) {
    use_ok('XPathFeed::UserAgent');
    isa_ok(XPathFeed::UserAgent->new, 'LWP::UserAgent');
}

__PACKAGE__->runtests;

1;
