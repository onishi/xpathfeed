xpathfeed
=========

XPathFeed is a Perl module and a web application to generate RSS Feed from XPath.

As a web application XPathFeed is hosted at [XpathFeed.com](http://xpathfeed.com/).

As a web app
------------

### Deploy to Heroku

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/onishi/xpathfeed/tree/master)

### Run on your machine

The dependency list of XPathFeed as a web app is provided as cpanfile. You can install required modules by `cpanm --installdeps .`.

```
$ cpanm --installdeps . # or `carton install`
$ XPF_ACCESS_LOG=STDERR carton exec plackup
```

#### Carton

You can use `carton install` instead of `cpanm --installdeps .`. The version of perl on which `cpanfile.lock` is build is indicated in the .perl-version file. If you use another (different) version of perl, delete `cpanfile.lock` to avoid troubles with core modules.

### Environment variables

- Cache
  - `XPF_CACHE` - Determines what cache module is used. If `Cache::Redis` is given, Cache::Redis is used. Otherwise Cache::FileCache is used.
  - Redis - There are three ways to set the Redis URL.
    - `REDISCLOUD_URL` - Set by Heroku when Redis Cloud add-on is enabled
    - `REDISTOGO_URL` - Set by Heroku when Redis To Go add-on is enabled
    - `REDIS_SERVER` - Parsed by [Redis](https://metacpan.org/pod/Redis) module or [Redis::Fast](https://metacpan.org/pod/Redis::Fast) module, which are used by Cache::Redis
- Access log
  - `XPF_ACCESS_LOG` - Determines where to output access log. If it is `STDERR`, access log is output into standard error output. Otherwise the value is treated as a file path. The default value is `/var/log/app/access_log`.
- Google Analytics
  - `GA_WEB_PROPERTY_ID` - Google Analytics web property ID (If empty, Google Analytics is disabled.)
  - `GA_CONFIG` - The last parameter for `ga('create')`

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
