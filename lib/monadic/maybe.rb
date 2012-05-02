module Monadic
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

    def initialize(*args)
      raise NoMethodError, "private method `new' called for #{self.class.name}, use `unit' instead"
    end

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
    def initialize(value)
      @value = join(value)
    end

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
        raise NoValueError, "Nothing has no value" if default.nil?
        default
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
