# ChangeLog

## unreleased

## v3.5.1 (2019-05-25)

* Enable frozen string literals [@toy](https://github.com/toy)

## v3.5.0 (2018-10-19)

* Add `Progress.without_beeper` for stopping periodical refresh of progress/eta for the duration of the block [@toy](https://github.com/toy)

## v3.4.0 (2017-10-11)

* Remove special handling for CSV in ruby 1.8 [@toy](https://github.com/toy)
* Set minimum ruby version to 1.9.3 [@toy](https://github.com/toy)
* Support `Enumerable#each_with_index` which stopped working since [45435b3](https://github.com/toy/progress/commit/45435b31ae0f9ad42255d9105d264f5fe9722c88) ([v3.2.2](#v322-2016-07-27)), not compatible with ruby 1.8 [#9](https://github.com/toy/progress/pull/9) [@amatsuda](https://github.com/amatsuda)

## v3.3.2 (2017-10-09)

* Support `Enumerable#each_with_index` which stopped working since [45435b3](https://github.com/toy/progress/commit/45435b31ae0f9ad42255d9105d264f5fe9722c88) ([v3.2.2](#v322-2016-07-27)), compatible with ruby 1.8 [#10](https://github.com/toy/progress/pull/10) [@amatsuda](https://github.com/amatsuda)

## v3.3.1 (2017-02-22)

* Fix for jruby raising wrong exception when checking if io is seekable [@toy](https://github.com/toy)

## v3.3.0 (2017-01-30)

* Add public setter for `io` and make `io` and `io_tty?` methods public [#8](https://github.com/toy/progress/issues/8) [@toy](https://github.com/toy)

## v3.2.2 (2016-07-27)

* Fix block arguments for `Hash` in ruby < 1.9 [@toy](https://github.com/toy)

## v3.2.1 (2016-07-26)

* Fix `respond_to?` for non existing methods in ruby < 1.9 [@toy](https://github.com/toy)

## v3.2.0 (2016-07-26)

* Provide `respond_to_missing?` instead of `respond_to?` in `WithProgress` [@toy](https://github.com/toy)

## v3.1.1 (2016-01-11)

* Fix `Thread.exclusive` deprecation in Ruby 2.3.0 [#4](https://github.com/toy/progress/pull/4) [@katsuma](https://github.com/katsuma)

## v3.1.0 (2014-12-22)

* Add handling for CSV in ruby 1.8 [@toy](https://github.com/toy)
* Fix getting total for progress on `Range` [@toy](https://github.com/toy)
* Use `StringIO` for `String` progress and `pos`/`size` for `IO` progress to not convert to array before progress [@toy](https://github.com/toy)
* Set `WithProgress` title to `nil` by default [@toy](https://github.com/toy)
* Fix return value from `with_progress{}` to equal `with_progress.each{}` [@toy](https://github.com/toy)
* Fix wrong variable name in `WithProgress#respond_to?` [@toy](https://github.com/toy)
* Fix using wrong constant `TempFile` instead of `Tempfile` [@toy](https://github.com/toy)
* Remove methods `eta` and `elapsed` created for mocking eta [@toy](https://github.com/toy)
* Rename `set_terminal_title` to `terminal_title` [@toy](https://github.com/toy)

## v3.0.2 (2014-12-19)

* Restore updating eta when there is no progress [@toy](https://github.com/toy)

## v3.0.1 (2014-08-18)

* Step once when running without block [@toy](https://github.com/toy)
* Fix working with `in_threads` by removing `WithProgress` inheritance of `Delegator` [@toy](https://github.com/toy)

## v3.0.0 (2013-08-20)

* Befriend with [`in_threads`](https://rubygems.org/gems/in_threads) gem [@toy](https://github.com/toy)
* Warn and use `to_a` on `IO` and `String` related objects before running progress, for other objects use for length in order: `size`, `length`, `count` [@toy](https://github.com/toy)
* Make `WithProgress` inherit `Delegator` [@toy](https://github.com/toy)
* Show elapsed time on finish [@toy](https://github.com/toy)
* Cleanup/rewrite, extract `Eta` and `Beeper` [@toy](https://github.com/toy)
* Conditionally require active_record support instead of conditionally creating module [@toy](https://github.com/toy)
* Don't kill dead thread for eta output without progress [@toy](https://github.com/toy)
* Don't show eta until at least one second passed [@toy](https://github.com/toy)

## v2.4.0 (2012-01-03)

* Add `Progress.running?` for checking if progress is running [@toy](https://github.com/toy)

## v2.3.0 (2011-12-25)

* Better handle edge cases of eta output without progress [@toy](https://github.com/toy)
* Call each only once for enumerable that can not be reused [@toy](https://github.com/toy)
* Allow to set length directly when calling `with_progress` [@toy](https://github.com/toy)

## v2.2.0 (2011-12-05)

* Make `with_progress.with_progress` create new instance instead of changing current, added enumerable and title attribute readers [@toy](https://github.com/toy)

## v2.1.1 (2011-12-04)

* Fix `with_progress.with_progress` with block not calling each [@toy](https://github.com/toy)

## v2.1.0 (2011-11-29)

* Change title when overriding progress with another call to `with_progress` [@toy](https://github.com/toy)
* Allow to directly specify length when initialising `WithProgress` [@toy](https://github.com/toy)

## v2.0.0 (2011-11-28)

* Show eta every second instead of every three when there is no progress [@toy](https://github.com/toy)
* Cache calculated length [@toy](https://github.com/toy)
* Use count method of enumerable if available to determine total for progress [@toy](https://github.com/toy)
* Call `each` with progress when `with_progress` is called with block [@toy](https://github.com/toy)
* Stop thread triggering eta update [@toy](https://github.com/toy)
* Rework `WithProgress` [@toy](https://github.com/toy)
* Remove `each_with_progress` and `each_with_index_and_progress` [@toy](https://github.com/toy)

## v1.2.1 (2011-10-18)

* Add missing `require 'thread'` [@toy](https://github.com/toy)

## v1.2.0 (2011-10-18)

* Updated eta every 3 seconds if nothing is happening [@toy](https://github.com/toy)

## v1.1.3 (2011-01-15)

* Fix `io` method, so `$stderr` can be silenced using `reopen` [@toy](https://github.com/toy)
* Remove `require 'rubygems'` [@toy](https://github.com/toy)

## v1.1.2.1 (2010-12-15)

* Internal gem changes [@toy](https://github.com/toy)

## v1.1.2 (2010-12-09)

* Use control character to clear line to end [@toy](https://github.com/toy)

## v1.1.1 (2010-12-07)

* Fix in notes handling [@toy](https://github.com/toy)

## v1.1.0 (2010-12-07)

* Add note for step [@toy](https://github.com/toy)

## v1.0.1 (2010-11-14)

* Fix progress by using `step` with block everywhere [@toy](https://github.com/toy)
* Separate `step` arguments to numerator and denominator [@toy](https://github.com/toy)

## v1.0.0 (2010-11-14)

* Show progress in terminal title [@toy](https://github.com/toy)
* Add eta [@toy](https://github.com/toy)
* Fix `step` by implementing through `set` and fix `set` return value  [@toy](https://github.com/toy)

## v0.4.1 (2010-11-13)

* Fix active record batch extension inclusion [@toy](https://github.com/toy)

## v0.4.0 (2010-11-13)

* Add support for active record batch progress [@toy](https://github.com/toy)
* Fix `each_with_index_and_progress` requiring title [@toy](https://github.com/toy)

## v0.3.0 (2010-11-13)

* Allow progress without title [@toy](https://github.com/toy)

## v0.2.2 (2010-01-20)

* Fix bug in i18n gem [@toy](https://github.com/toy)

## v0.2.1 (2010-01-16)

* Ensure outputting final 100% of outer progress [@toy](https://github.com/toy)

## v0.2.0 (2009-12-30)

* Limit frequency of progress output [@toy](https://github.com/toy)

## v0.1.2 (2009-12-29)

* Internal gem changes [@toy](https://github.com/toy)

## v0.1.1.3 (2009-09-28)

* Remove debugging character from output [@toy](https://github.com/toy)

## v0.1.1.2 (2009-09-28)

* Fix highlighting [@toy](https://github.com/toy)

## v0.1.1.0 (2009-09-21)

* Allow `Progress(…)` instead `Progress.start(…)` [@toy](https://github.com/toy)
* Allow `step` to accept block for valid counting of custom progress [@toy](https://github.com/toy)
* Kill progress on cycle break [@toy](https://github.com/toy)

## v0.1.0.3 (2009-09-21)

* Internal gem changes [@toy](https://github.com/toy)

## v0.1.0.2 (2009-08-19)

* Don't raise error on extra `Progress.stop` [@toy](https://github.com/toy)

## v0.1.0.1 (2009-08-19)

* Fix output by verifying and converting progress to float [@toy](https://github.com/toy)

## v0.1.0.0 (2009-08-19)

* Inner progress increases outer progress, ability to set progress using `set` alongside stepping using `step` [@toy](https://github.com/toy)

## v0.0.9.3 (2009-08-06)

* Use space instead of `'>'` for padding [@toy](https://github.com/toy)

## v0.0.9.2 (2009-07-28)

* Force behaving as with tty by setting `PROGRESS_TTY` environment variable [@toy](https://github.com/toy)

## v0.0.9.1 (2009-07-28)

* Separate handling of staying on same line and colourising output [@toy](https://github.com/toy)

## v0.0.9.0 (2009-07-20)

* Add `Enumerable#with_progress` on which any enumerable method can be called [@toy](https://github.com/toy)

## v0.0.8.1 (2009-05-02)

* Return to line start after printing message instead of before [@toy](https://github.com/toy)

## v0.0.8 (2009-04-27)

* No colours and don't stay on same line when not on tty or explicitly using `:lines => true` option [@toy](https://github.com/toy)

## v0.0.7.1 (2009-04-24)

* Internal gem changes [@toy](https://github.com/toy)

## v0.0.7 (2009-03-24)

* Internal gem changes [@toy](https://github.com/toy)

## v0.0.6 (2009-02-19)

* Output to stderr [@toy](https://github.com/toy)

## v0.0.5 (2008-11-07)

* Return result of enumerable method [@toy](https://github.com/toy)

## v0.0.4 (2008-11-06)

* Allow to change step size [@toy](https://github.com/toy)

## v0.0.3 (2008-11-01)

* Output final newline after finishing progress [@toy](https://github.com/toy)

## v0.0.2 (2008-10-31)

* Allow enclosed progress [@toy](https://github.com/toy)

## v0.0.1 (2008-08-10)

* Initial [@toy](https://github.com/toy)
