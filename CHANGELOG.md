# Changelog

## v0.0.3

`Some#map` and `Some#select` accept proc and block, you can now use:

    Option("FOO").map(&:downcase)           # NEW
    Option("FOO").map { |e| e.downcase }    # old
    Option("FOO").downcase                  # old

Removed `#none?`, please use `#empty?` instead.
