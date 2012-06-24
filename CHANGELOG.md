# Changelog

## v0.6

Extend `Try` to also support lambdas.

The first parameter of `Try` can be used as a predicate and the block as formatter

    Try(true)                              == Success(true)
    Try(false) { "string" }                == Failure("string")
    Try(false) { "success" }.else("fail")  == Failure("fail")

`Maybe` supports `#proxy` to avoid naming clashes between the underlying value and `Maybe` itself.

    Maybe({a: 1}).proxy.fetch(:a)          == Maybe(1)
    # this is in effect syntactic sugar for
    Maybe({a: 1}).map {|e| e.fetch(:a) }

`Nothing#or` coerces the or value into a Maybe, thus

    Maybe(nil).or(1)          == Just(1)
    Maybe(nil).or(nil)        == Nothing

`Either` coerces now `Just` and `Nothing` into `Success` and `Failure`

    Either(Just.new(1))       == Success(1)
    Either(Nothing)           == Failure(Nothing)

## v0.5.0

Add the `Try` helper which works similar to Either, but takes a block

    Try { Date.parse('2012-02-30') }       == Failure
    Try { Date.parse('2012-02-28') }       == Success

`Either` else now supports also a block

    Failure(1).else {|other| 1 + 2 }       == Failure(3)

## v0.4.0
`#or` returns for Nothing an alternative

    Maybe(nil).or(1)          == 1
    Maybe(1).or(2)            == 1

## v0.3.0
**BREAKING CHANGES**
`#to_s` returns the inner value converted to string

## v0.2.1
Nothing has no method #name ... will need to use `BasicObject`

## v0.2.0
**BREAKING CHANGES**

`Monad#map` does not recognize `Enumerables` automatically anymore. It just maps, as a `Functor`.  
Instead the new `Monad#flat_map` function operates on the underlying value as on `Enumerable`.

`Either#else` allows to exchange the inner value of  `Nothing` to an alternative value.

    Either(false == true).else('false was not true')          == Failure(false was not true)
    Success('truth needs no sugar coating').else('all lies')  == Success('truth needs no sugar coating')

## v0.1.1

`Either()` coerces only `StandardError` to `Failure`, other exceptions higher in the hierarchy are will break the flow.  
Thanks to @pithyless for the suggestion.

Monad is now a Module instead of a Class as previously. This fits the Monad metaphor better. Each monad must now implement the unit method itself, which is the correct way to do anyway.


## v0.1.0

You can now chain Eithers with `+` without providing a block or a proc:

    Success(1) + Failure(2)     == Failure(2)
    Failure(1) + Failure(2)     == Failure(1)

All monads now have the `#to_ary` and `#to_a` method, which coerces the inner value into an `Array`.

I am considering the Api now almost stable, the only thing I am not so sure about, 
is whether to apply the magic coercion or not.

`Validation()` now returns the successfully validated values.
See [examples/validation.rb](https://github.com/pzol/monadic/blob/master/examples/validation.rb)
and [examples/validation_module](https://github.com/pzol/monadic/blob/master/examples/validation_module.rb)


## v0.0.7

Implements the #map method for all Monads. It works on value types and on Enumerable collections.  
Provide a proc or a block and it will return a transformed value or collection boxed back in the monad.

    Monad.unit('FOO').map(&:capitalize).map {|v| "Hello #{v}"}    == Monad(Hello Foo)

Add the Elvis operator _? - ruby does not allow ?: as operator and use it like the excellent [andand](https://github.com/raganwald/andand)

    nil._?           == Nothing
    "foo"._?         == 'foo'
    {}._?.a.b        == Nothing
    {}._?[:foo]      == Nothing

## v0.0.6
**Contains Breaking Changes**

Refactoring to use internal `Monad` class, from which all monads inherit.

Reimplemented `Maybe` as inherited class from `Monad`. The old `Option` implementation has been removed, maybe does the same though, but the code is much cleaner and obeys the 3 monadic laws.

Removed `Maybe#fetch` call with block`

`Either` and `Validation` are now in the `Monadic` namespace.

Added Travis-Ci integration, [![Build Status](https://secure.travis-ci.org/pzol/monadic.png?branch=master)](http://travis-ci.org/pzol/monadic)


## v0.0.5

Removed the `#chain` method alias for bind in `Either`.

Moar examples with instance variables in an `Either.chain`.

Add monadic `Validation`, which is a special application (an applicative functor) of the Either Monad e.g.

    Validation() do
      check { check_age.(person.age);          }
      check { check_sobriety.(person.sobriety) }
    end

It returns a Success([]) with an empty list, or a Failure([..]) with a list of all Failures.

## v0.0.4

To be more idiomatic rubyuesque, rename `#value` to `#fetch`, which throws now an `NoValueError`.  
Thanks to [@pithyless](https://twitter.com/#!/pithyless) for the suggestion.

It now supports the Either monad, e.g.

    either = Success(0).
      bind { Success(1) }.
      bind { Failure(2) }.
      bind { Success(3) }

    either == Failure(2)      # the third bind is NOT executed  

## v0.0.3

`Some#map` and `Some#select` accept proc and block, you can now use:

    Option("FOO").map(&:downcase)           # NEW
    Option("FOO").map { |e| e.downcase }    # old
    Option("FOO").downcase                  # old

Removed `#none?`, please use `#empty?` instead.

`Some` and `None` are now in the `Monadic` namespace, however they are aliased when requiring `monadic`
