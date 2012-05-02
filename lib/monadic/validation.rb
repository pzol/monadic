module Monadic
  # Wraps the construction of the Validation class
  def Validation(&block)
    Validation.new.call(&block)
  end

  # Conducts several function calls which do checks, of which each must return Success or Failure
  # and returns a list of all failures. 
  # Validation is not a monad, but an deemed an applicative functor
  class Validation
    def initialize
      @result = Success([])
    end

    def call(&block)
      instance_eval(&block)
    end

    # 
    def check(proc=nil, &block)
      result = (proc || block).call
      raise NotEitherError, "Expected #{result.inspect} to be an Either" unless result.is_a? Either
      @result = Failure(@result.fetch << result.fetch) if result.failure?

      @result
    end
  end
end
