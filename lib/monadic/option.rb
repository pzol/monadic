require 'singleton'

def Option(value)
  return None if value.nil? || (value.respond_to?(:empty?) && value.empty?)
  return Some.new(value)
end
alias :Some :Option

class Some 
  def initialize(value)
    @value = value
  end

  def none?
    @value.is_a? None
  end
  alias :empty? :none?

  def truly?
    @value == true
  end

  def else(default)
    return default if none?
    return self
  end  

  def to_ary
    return [@value].flatten if @value.respond_to? :flatten
    return [@value]
  end
  alias :to_a :to_ary

  def map(&block)
    return Option(@value.map(&block)) if @value.is_a?(Enumerable)
    return Option(block.call)
  end

  def select(&block)
    return Option(@value.select(&block)) if @value.is_a?(Enumerable)
    return None unless block.call(@value)
    return self
  end

  def value(default=None, &block)
    return default if none?
    return block.call(@value)  if block_given?
    return @value
  end  
  alias :or :value
  alias :_  :value

  def method_missing(m, *args)
    Option(@value.__send__(m, *args))
  end  

  def ==(other)
    return false unless other.is_a? Some
    @value == other.instance_variable_get(:@value)
  end  
end

class None
  class << self
    def method_missing(m, *args)
      self
    end

    def value(default=self)
      default
    end
    alias :or :value
    alias :_  :value

    def to_ary
      []
    end
    alias :to_a :to_ary

    def truly?
      false
    end
  end
end
