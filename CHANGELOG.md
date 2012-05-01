# Changelog

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
