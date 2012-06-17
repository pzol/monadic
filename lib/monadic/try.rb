module Monadic
  def Try(proc = nil, &block)
    begin
      return Either(proc) unless proc.nil? || proc.is_a?(Proc)
      return Either((proc || block).call)
    rescue => error
      Failure(error)
    end
  end
end
