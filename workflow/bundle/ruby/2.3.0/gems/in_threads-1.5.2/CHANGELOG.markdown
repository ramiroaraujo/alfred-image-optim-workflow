# ChangeLog

## unreleased

## v1.5.2 (2019-05-25)

* Enable frozen string literals [@toy](https://github.com/toy)

## v1.5.1 (2018-12-30)

* Register `chain` to run without threads [@toy](https://github.com/toy)

## v1.5.0 (2017-11-17)

* Use thread pool instead of creating a thread for every iteration [@toy](https://github.com/toy)
* Handle `break` (also with argument) and exceptions raised in `each` method of enumerable [@toy](https://github.com/toy)
* Register `lazy` to run without threads [@toy](https://github.com/toy)

## v1.4.0 (2017-03-19)

* Register `sum` and `uniq` to run in threads and `chunk_while` to run without threads [@toy](https://github.com/toy)
* Register `grep_v` to call block in threads [@toy](https://github.com/toy)
* Fix Segmentation fault in ruby 2.0 [@toy](https://github.com/toy)
* Fix not sending all block arguments to methods not returning original enumerable [@toy](https://github.com/toy)
* Fix for a [bug](https://bugs.ruby-lang.org/issues/13313) in ruby 2.4.0 causing Segmentation fault [@toy](https://github.com/toy)
* Clean up documentation [#1](https://github.com/toy/in_threads/pull/1) [@hollingberry](https://github.com/hollingberry)

## v1.3.1 (2015-01-09)

* Register `to_h`, `slice_after` and `slice_when` to run without threads [@toy](https://github.com/toy)
* Remove special handling of methods running without threads [@toy](https://github.com/toy)

## v1.3.0 (2014-10-31)

* Fix not thread safe code for jruby [@toy](https://github.com/toy)

## v1.2.2 (2014-08-08)

* Fix silencing exceptions raised in blocks [@toy](https://github.com/toy)

## v1.2.1 (2014-04-06)

* Use explicit requires instead of autoload [@toy](https://github.com/toy)

## v1.2.0 (2013-08-20)

* Befriend with [`progress`](https://rubygems.org/gems/progress) gem [@toy](https://github.com/toy)
* Use `Delegator` instead of undefining methods [@toy](https://github.com/toy)

## v1.1.2 (2013-08-02)

* Fix for jruby stalling [@toy](https://github.com/toy)
* Fix for rubinius not raising `NoMethodError` for undefined methods [@toy](https://github.com/toy)
* Register `to_set` to run without threads [@toy](https://github.com/toy)

## v1.1.1 (2011-12-13)

* Decrease priority of initiating block execution for methods not returning original enumerable [@toy](https://github.com/toy)
* Call each of enumerable only once for methods not returning original enumerable [@toy](https://github.com/toy)
* Remove class method `enumerable_methods` [@toy](https://github.com/toy)

## v1.1.0 (2011-12-08)

* Register `chunk` and `slice_before` to run without threads [@toy](https://github.com/toy)
* Register `flat_map` and `collect_concat` to run in threads [@toy](https://github.com/toy)
* Register `each_entry` to run in threads [@toy](https://github.com/toy)
* Register `each_with_object` to run without threads [@toy](https://github.com/toy)
* Add argument checking [@toy](https://github.com/toy)
* Use faster method for `each` [@toy](https://github.com/toy)

## v1.0.0 (2011-12-05)

* Fix for blocks with multiple arguments (`each_with_index`, `enum_with_index`) [@toy](https://github.com/toy)
* Rewrite: properly working with all compatible `Enumerable` methods, otherwise running without threads [@toy](https://github.com/toy)

## v0.0.4 (2010-12-15)

* Internal gem changes [@toy](https://github.com/toy)

## v0.0.3 (2010-07-13)

* Fix thread count overflow [@toy](https://github.com/toy)

## v0.0.2 (2009-12-29)

* Internal gem changes [@toy](https://github.com/toy)

## v0.0.1 (2009-09-21)

* Initial [@toy](https://github.com/toy)
