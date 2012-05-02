module Monadic
  # thrown by Option#fetch if it has no value and no default was provided
  class NoValueError < StandardError; end

  # thrown when a Success or Failure was expected, but anything else was returned
  class NotEitherError < StandardError; end 
end
