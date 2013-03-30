package XPathFeed::UserAgent;
use strict;
use warnings;
use base qw/LWP::UserAgent/;

sub new {
    my($class, %cnf) = @_;
    $class->SUPER::new(
        agent   => 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)',
        timeout => 30,
        %cnf,
    );
}

1;
