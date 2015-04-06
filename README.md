xpathfeed
=========

XPathFeed is a Perl module and a web application to generate RSS Feed from XPath.

As a web application XPathFeed is hosted at [XpathFeed.com](http://xpathfeed.com/).

As a web app
------------

### Demo

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/onishi/xpathfeed/tree/master)

#### demo site

[XpathFeed.com](http://xpathfeed.com/)

As a Perl module
----------------

### SYNOPSIS

```perl
use XPathFeed;

my $x = XPathFeed->new;
$x->url($url);
$x->xpath_list($xpath);
print $x->feed;
```

### DESCRIPTION

XPathFeed is a feed generator from xpath.

```perl
use XPathFeed;
my $x = XPathFeed->new;
$x->url($url);
$x->xpath_list($xpath);
print $x->feed;
```
or

`plackup app.psgi`

AUTHOR
------

Yasuhiro Onishi <yasuhiro.onishi@gmail.com>

LICENSE
-------

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
