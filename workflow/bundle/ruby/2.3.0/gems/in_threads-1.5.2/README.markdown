[![Gem Version](https://img.shields.io/gem/v/in_threads.svg?style=flat)](https://rubygems.org/gems/in_threads)
[![Build Status](https://img.shields.io/travis/toy/in_threads/master.svg?style=flat)](https://travis-ci.org/toy/in_threads)
[![Code Climate](https://img.shields.io/codeclimate/maintainability/toy/in_threads.svg?style=flat)](https://codeclimate.com/github/toy/in_threads)
[![Depfu](https://badges.depfu.com/badges/0579058f30df655f684aff1be244691e/overview.svg)](https://depfu.com/github/toy/in_threads)
[![Inch CI](https://inch-ci.org/github/toy/in_threads.svg?branch=master&style=flat)](https://inch-ci.org/github/toy/in_threads)

# in_threads

Run all possible enumerable methods in concurrent/parallel threads.

```ruby
urls.in_threads(20).map do |url|
  HTTP.get(url)
end
```

## Installation

Add the gem to your Gemfile...

```ruby
gem 'in_threads'
```

...and install it with [Bundler](http://bundler.io).

```sh
$ bundle install
```

Or install globally:

```sh
$ gem install in_threads
```

## Usage

Let's say you have a list of web pages to download.

```ruby
urls = [
  "https://google.com",
  "https://en.wikipedia.org/wiki/Ruby",
  "https://news.ycombinator.com",
  "https://github.com/trending"
]
```

You can easily download each web page one after the other.

```ruby
urls.each do |url|
  HTTP.get(url)
end
```

However, this is slow, especially for a large number of web pages. Instead,
download the web pages in parallel with `in_threads`.

```ruby
require 'in_threads'

urls.in_threads.each do |url|
  HTTP.get(url)
end
```

By calling `in_threads`, the each web page is downloaded in its own thread,
reducing the time by almost 4x.

By default, no more than 10 threads run at any one time. However, this can be
easily overriden.

```ruby
# Read all XML files in a directory
Dir['*.xml'].in_threads(100).each do |file|
  File.read(file)
end
```

Predicate methods (methods that return `true` or `false` for each object in a
collection) are particularly well suited for use with `in_threads`.

```ruby
# Are all URLs valid?
urls.in_threads.all? { |url| HTTP.get(url).status == 200 }

# Are any URLs invalid?
urls.in_threads.any? { |url| HTTP.get(url).status == 404 }
```

You can call any `Enumerable` method, but some (`#inject`, `#reduce`, `#max`,
`#min`, `#sort`, `#to_a`, and others) cannot run concurrently, and so will
simply act as if `in_threads` wasn't used.

### Break and exceptions

Exceptions are caught and re-thrown after allowing blocks that are still running to finish.

**IMPORTANT**: only the first encountered exception is propagated, so it is recommended to handle exceptions in the block.

`break` is handled in ruby >= 1.9 and should be handled in jruby [after 9.1.9.0](https://github.com/jruby/jruby/issues/4697). Handling is done in special way: as blocks are run outside of original context, calls to `break` cause `LocalJumpError` which is caught and its result is returned.

## Copyright

Copyright (c) 2009-2019 Ivan Kuchin. See LICENSE.txt for details.
