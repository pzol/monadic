module Monadic
  # @abstract Chains function calls and stops executing if one of them fails.
  class Either < Monad
    def self.chain(initial=nil, &block)
      Either::Chain.new(&block).call(initial)
    end

    def self.unit(value)
      return Failure.new(value) if value.nil? || (value.respond_to?(:empty?) && value.empty?) || !value
      return Success.new(value)
    end

    # Initialize is private, because it always would return an instance of Either, but Success or Failure 
    # are required (Either is abstract).
    def initialize(value)
      raise NoMethodError, "private method `new' called for #{self.class.name}, use `unit' instead"
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

  # @private instance and class methods for Success and Failure
  module SuccessFailure
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
    extend  SuccessFailure::ClassMethods
    include SuccessFailure::InstanceMethods
  end

  class Failure < Either
    extend  SuccessFailure::ClassMethods
    include SuccessFailure::InstanceMethods
  end

  def Failure(value)
    Failure.new(value)
  end

  # Factory method 
  # @return [Success]
  def Success(value)
    Success.new(value)
  end

  # Magic factory
  # @return [Success, Failure] depending whether +value+ is falsey
  def Either(value)
    Either.unit(value)
  end
end
