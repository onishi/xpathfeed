#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use XPathFeed;

my ($url, $xpath) = @ARGV;

warn "$url $xpath";

my $x = XPathFeed->new(
    url        => $url,
    xpath_list => $xpath,
);

print $x->feed;
