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
      !!@value == true
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

    class Proxy < BasicObject
      def initialize(maybe)
        @maybe = maybe
      end

      def method_missing(m, *args)
        @maybe.map { |e| e.__send__(m, *args)  }
      end

      def __fetch__
        @maybe.fetch
      end
    end

    def proxy
      @proxy ||= Proxy.new(self)
    end

    # @return always self for Just
    def or(other)
      self
    end
  end

  # Represents a NullObject
  class Nothing < Maybe
    class << self
      undef name

      # @return the default value passed
      def fetch(*args)
        args.length == 0 ?
          Nothing :
          args[0]
      end
      alias :_ :fetch

      def method_missing(m, *args)
        self
      end

      # @return an alternative value, the passed value is coerced into Maybe, thus Nothing.or(1) will be Just(1)
      def or(other)
        Maybe.unit(other)
      end

      # def respond_to?
      # end

      def to_ary
        []
      end
      alias :to_a :to_ary

      def to_s(*args)
        'Nothing'
      end

      def to_json(*args)
        'null'
      end

      def truly?
        false
      end

      def empty?
        true
      end

      def ===(other)
        other == Nothing
      end

      def coerce(other)
        raise TypeError
      end
    end
  end

  def Maybe(value)
    Maybe.unit(value)
  end
  alias :Just     :Maybe
  alias :Nothing  :Maybe
end
