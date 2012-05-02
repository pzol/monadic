# Represents optional values. Instances of Option are either an instance of Some or the object None.

# Represents the Option if there is some value available
module Monadic
  # Helper function which returns Some or None respectively, depending on their value
  # I find this moar simplistic in ruby than the traditional #bind and #unit
  def Option(value)
    return Monadic::None if value.nil? || (value.respond_to?(:empty?) && value.empty?)
    return Monadic::Some.new(value)
  end
  alias :Some  :Option
  alias :Maybe :Option

  class Some
    def initialize(value)
      @value = value
    end

    def to_ary
      return [@value].flatten if @value.respond_to? :flatten
      return [@value]
    end
    alias :to_a :to_ary

    def empty?
      false
    end

    def truly?
      @value == true
    end

    def fetch(default=None, &block)
      return block.call(@value)  if block_given?
      return @value
    end
    alias :or :fetch
    alias :_  :fetch

    def map(func = nil, &block)
      return Option(@value.map(&block)) if @value.is_a?(Enumerable)
      return Option((func || block).call(@value))
    end

    def method_missing(m, *args)
      Option(@value.__send__(m, *args))
    end

    def select(func = nil, &block)
      return Option(@value.select(&block)) if @value.is_a?(Enumerable)
      return None unless (func || block).call(@value)
      return self
    end

    def to_s
      "Some(#{@value.to_s})"
    end

    def ==(other)
      return false unless other.is_a? Some
      @value == other.instance_variable_get(:@value)
    end    
  end

  # Represents the Option if there is no value available
  class None
    class << self
      def to_ary
        []
      end
      alias :to_a :to_ary

      def empty?
        true
      end

      def fetch(default=nil)
        raise NoValueError if default.nil?
        default
      end
      alias :or :fetch
      alias :_  :fetch

      def method_missing(m, *args)
        self
      end

      def to_s
        'None'
      end

      def truly?
        false
      end

    end
  end
end
