module Monadic 
  class Monad
    def self.unit(value)
      new(value)
    end

    def initialize(value)
      @value = join(value)
    end

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
    def fetch
      @value
    end
    alias :_ :fetch

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
