module Monadic 
  module Monad
    def initialize(value)
      @value = join(value)
    end

    # Allows priviledged access to the inner value of the Monad from within the block
    def bind(proc=nil, &block)
      (proc || block).call(@value)
    end

    # If the passed value is monad already, get the value to avoid nesting
    # M[M[A]] is equivalent to M[A]
    def join(value)
      if value.is_a? self.class then value.fetch
      else value end
    end

    # Unwraps the the Monad
    # @return the value contained in the monad
    def fetch
      @value
    end
    alias :_ :fetch

    # A functor applying the proc or block on the boxed `value` and returning the Monad with the transformed values.
    # If the underlying `value` is an `Enumerable`, the map is applied on each element of the collection.
    # (A -> B) -> M[A] -> M[B]
    def map(proc = nil, &block)
      func = (proc || block)
      return self.class.unit(@value.map {|v| func.call(v) }) if @value.respond_to? :map
      return self.class.unit(func.call(@value))
    end

    # @return [Array] a with the values inside the monad
    def to_ary
      Array(@value)
    end
    alias :to_a :to_ary
      
    # Return the string representation of the Monad
    def to_s
      pretty_class_name = self.class.name.split('::')[-1]
      "#{pretty_class_name}(#{@value.nil? ? 'nil' : @value.to_s})"
    end

    def ==(other)
      return false unless other.is_a? self.class
      @value == other.instance_variable_get(:@value)
    end
  end
end
