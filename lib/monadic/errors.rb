module Monadic
  # thrown by Option#fetch if it has no value and no default was provided
  class NoValueError < StandardError; end
end
