module Monadic
  # @abstract Chains function calls and stops executing if one of them fails.
  class Either < Monad
    def self.chain(initial=nil, &block)
      Either::Chain.new(&block).call(initial)
    end

    def self.unit(value)
      return value if value.is_a? Either
      return Failure.new(value) if value.nil? || (value.respond_to?(:empty?) && value.empty?) || !value
      return Success.new(value)
    end

    # Initialize is private, because it always would return an instance of Either, but Success or Failure 
    # are required (Either is abstract).
    private_class_method :new

    # Allows privileged access to the +Either+'s inner value from within a block. 
    # This block should return a +Success+ or +Failure+ itself. It will be coerced into #Either
    # @return [Success, Failure]
    def bind(proc=nil, &block)
      return self if failure?
      return concat(proc) if proc.is_a? Either

      begin
        Either(call(proc, block))
      rescue Exception => ex
        Failure(ex)      
      end
    end
    alias :>=  :bind
    alias :+   :bind

    def fetch(default=@value)
      return default if failure?
      return @value
    end

    alias :_     :fetch
    def success?
      is_a? Success
    end

    def failure?
      is_a? Failure
    end

    private 
    def call(proc=nil, block)
      func = (proc || block)
      raise "No block or lambda given" unless func.is_a? Proc
      (func.arity == 0 ? func.call : func.call(@value)) || Failure(nil)
    end

    def concat(other)
      failure? ? self : other
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

  # @private instance and class methods for +Success+ and +Failure+
  module SuccessFailure
    def self.included(base)
      base.class_eval do
        public_class_method :new
        extend  ClassMethods
        include InstanceMethods
      end
    end
    module ClassMethods
      def unit(value)
        new(value)
      end
    end
    module InstanceMethods
      def initialize(value)
        @value = join(value)
      end 
    end
  end

  class Success < Either
    include SuccessFailure
  end

  class Failure < Either
    include SuccessFailure
  end

  def Failure(value)
    Failure.new(value)
  end

  # Factory method 
  # @return [Success]
  def Success(value)
    Success.new(value)
  end

  # Coerces any value into either a +Success+ or a +Failure+.
  # @return [Success, Failure] depending whether +value+ is falsey i.e. nil, false, Enumerable#empty? become +Failure+, all other `Success`
  def Either(value)
    Either.unit(value)
  end
end
