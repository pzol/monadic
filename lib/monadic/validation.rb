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
      @result = []
    end

    def call(&block)
      instance_eval(&block)

      if @result.any?(&:failure?)
        Failure(@result.select(&:failure?).map(&:fetch))
      else
        Success(@result.select(&:success?).map(&:fetch))
      end
    end

    # 
    def check(proc=nil, &block)
      result = (proc || block).call
      raise NotEitherError, "Expected #{result.inspect} to be an Either" unless result.is_a? Either
      # @failure.fetch << result.fetch) if result.failure?
      @result << result
    end
  end
end
