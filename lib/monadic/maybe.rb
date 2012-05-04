module Monadic
  # @api private helps treating `Maybe` like Either in Scala
  module ScalaStuff
    def map(proc = nil, &block)
      return Maybe(@value.map(&block)) if @value.is_a?(Enumerable)
      return Maybe((proc || block).call(@value))
    end

    def select(proc = nil, &block)
      return Maybe(@value.select(&block)) if @value.is_a?(Enumerable)
      return Nothing unless (proc || block).call(@value)
      return self
    end
  end

  class Maybe < Monad
    include ScalaStuff

    def self.unit(value)
      return Nothing if value.nil? || (value.respond_to?(:empty?) && value.empty?)
      return Just.new(value)
    end

    # Initialize is private, because it always would return an instance of Maybe, but Just or Nothing 
    # are required (Maybe is abstract).
    private_class_method :new

    def empty?
      @value.respond_to?(:empty?) && @value.empty?
    end

    def to_ary
      return [@value].flatten if @value.respond_to? :flatten
      return [@value]
    end
    alias :to_a :to_ary

    def truly?
      @value == true
    end
  end

  class Just < Maybe
    public_class_method :new

    def fetch(default=nil)
      @value
    end
    alias :_ :fetch

    def method_missing(m, *args)
      Maybe(@value.__send__(m, *args))
    end
  end

  class Nothing < Maybe
    class << self
      def fetch(default=nil)
        return self if default.nil?
        return default
      end
      alias :_ :fetch

      def method_missing(m, *args)
        self
      end

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
