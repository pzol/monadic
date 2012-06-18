module Monadic
  ## Wrap a block or a predicate to always return Success or Failure.
  ## It will catch StandardError and return as a Failure.
  def Try(arg = nil, &block)
    begin
      predicate = arg.is_a?(Proc) ? arg.call : arg
      return Either(block.call) if block_given? && predicate.nil?
      return Either(predicate).class.unit(block.call) if block_given?   # use predicate for Success/Failure and block for value
      return Either(predicate)
    rescue => error
      Failure(error)
    end
  end
end
