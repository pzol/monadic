module Monadic
  # Chain various method calls
  module Either
    def self.chain(initial=nil, &block)
      Either::Chain.new(&block).call(initial)
    end

    def success?
      is_a? Success
    end

    def failure?
      is_a? Failure
    end

    def fetch(default=@value)
      return default if failure?
      return @value
    end
    alias :_     :fetch

    def bind(proc=nil, &block)
      return self if failure?

      begin
        result = if proc && proc.arity == 0 
                   then proc.call
                   else (proc || block).call(@value) 
                 end
        result ||= Failure(nil)
        result = Either(result) unless result.is_a? Either
        result    
      rescue Exception => ex
        Failure(ex)      
      end
    end
    alias :>=  :bind
    alias :+   :bind

    def to_s
      "#{pretty_class_name}(#{@value.nil? ? 'nil' : @value.to_s})"
    end

    def ==(other)
      return false unless self.class === other
      return other.fetch == @value
    end

    private
    def pretty_class_name
      self.class.name.split('::')[-1]
    end

  end

  class Either::Chain
    def initialize(&block)
      @chain = []
      instance_eval(&block)
    end

    def call(initial)
      @chain.inject(Success(initial)) do |result, current|
        result.bind(current)
      end
    end

    def bind(proc=nil, &block)
      @chain << (proc || block)
    end

  end

  class Success 
    include Either
    def initialize(value)
      @value = value
    end
  end

  class Failure 
    include Either
    def initialize(value)
      @value = value
    end
  end

  def Success(value)
    Success.new(value)
  end

  def Failure(value)
    Failure.new(value)
  end

  def Either(value)
    return Failure(value) if value.nil? || (value.respond_to?(:empty?) && value.empty?) || !value
    return Success(value)
  end
end
