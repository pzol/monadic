def Validation(&block)
  Validation.new.call(&block)
end

class Validation
  def initialize
    @result = Success([])
  end

  def call(&block)
    instance_eval(&block)
  end

  def check(proc=nil, &block)
    result = (proc || block).call
    raise NotEitherError, "Expected #{result.inspect} to be an Either" unless result.is_a? Either
    @result = Failure(@result.fetch << result.fetch) if result.failure?

    @result
  end
end
