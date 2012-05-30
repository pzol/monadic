module Monadic
  class Maybe 
    include Monadic::Monad
    
    def self.unit(value)
      return Nothing if value.nil? || (value.respond_to?(:empty?) && value.empty?)
      return Just.new(value)
    end

    # Initialize is private, because it always would return an instance of Maybe, but Just or Nothing 
    # are required (Maybe is abstract).
    private_class_method :new

    # @return true if the underlying object responds to #empty?, false otherwise
    def empty?
      @value.respond_to?(:empty?) && @value.empty?
    end

    # @return [Failure, Success] the Maybe Monad filtered with the block or proc expression
    def select(proc = nil, &block)
      func = (proc || block)
      return Maybe(@value.select {|v| func.call(v) }) if @value.respond_to? :select
      return Nothing unless func.call(@value)
      return self
    end

    # @return [true, false] true if the underlying value is true
    def truly?
      @value == true
    end
  end

  # Represents an existing value
  class Just < Maybe
    public_class_method :new

    # @return the underlying value
    def fetch(default=nil)
      @value
    end
    alias :_ :fetch

    def method_missing(m, *args)
      Maybe(@value.__send__(m, *args))
    end

    def inspect
      "Just(#{@value.inspect})"
    end

    # @return always self for Just
    def or(other)
      self
    end

    def to_s
      @value.to_s
    end
  end

  # Represents a NullObject
  class Nothing < Maybe
    class << self
      undef name

      # @return the default value passed
      def fetch(default=nil)
        return self if default.nil?
        return default
      end
      alias :_ :fetch

      def method_missing(m, *args)
        self
      end

      # @return an alternative value, the passed value is NOT coerced into Maybe, thus Nothing.or(nil) will be Just(nil)
      def or(other)
        Just.new(other)
      end

      # def respond_to?

      # end

      def to_ary
        []
      end
      alias :to_a :to_ary

      def to_s
        'Nothing'
      end

      def truly?
        false
      end
    end
  end

  def Maybe(value)
    Maybe.unit(value)
  end
  alias :Just     :Maybe
  alias :Nothing  :Maybe
end
