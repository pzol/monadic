require 'spec_helper'

describe 'Either' do
  it 'Success and Failure should be kind of Either' do
    Success.new(0).should be_kind_of(Either)
    Failure.new(0).should be_kind_of(Either)
  end

  it '#to_s works' do
    Success.new("it worked!").to_s.should == "Success(it worked!)"
    Failure.new(nil).to_s.should == "Failure(nil)"
  end

  it 'allows to verify equality' do
    Success(1).should == Success(1)
    Success(2).should_not == Success(1)
    Success(1).should_not == Failure(1)
    Failure(1).should == Failure(1)
    Failure(1).should_not == Failure(2)
  end

  it 'wraps a nil result to Failure' do
    Success(nil).bind { nil }.should == Failure(nil)
  end

  it 'catches exceptions and returns them as Failure' do
    either = Success(nil).
      bind { raise 'error' }

    either.should be_kind_of Failure
    error = either.fetch
    error.should be_kind_of RuntimeError
    error.message.should == 'error'
  end

  class User
    def self.find(id)
      case id 
      when -1; raise 'invalid user id'
      when  0; nil
      else User.new(id)
      end
    end

    attr_reader :name
    def initialize(id)
      @name = "User #{id}"
    end
  end

  it 'Either(nil || false) returns a Failure' do
    Either(nil).should == Failure(nil)
    Either(false).should == Failure(false)
    Failure.should === Either(nil)
  end

  it 'Either with a non-falsey value returns success' do
    Success.should === Either(1)
    Success.should === Either(true)
    Success.should === Either("string")
  end

  it 'works' do
    either = Either(true).
              bind -> { User.find(-1) }
    either.failure?.should be_true
    RuntimeError.should === either.fetch
  end

  it 'does NOT call subsequent binds on Failure and returns the first Failure in the end' do
    either = Success(0).
      bind { Failure(1) }.
      bind { Failure(2) }.
      bind { Success(3) }

    either.should == Failure(1)
  end

  it 'returns the last Success' do
    either = Success(nil).
      bind { Success(1) }.
      bind { Success(2) }

    either.should == Success(2)
  end

  it 'allows to #fetch the value of the Success or Failure' do
    Failure(1).fetch.should == 1
    Success(2).fetch.should == 2
  end

  it 'allows to #fetch the value with a default if it failed' do
    Failure(1).fetch(2).should == 2
    Success(1).fetch(2).should == 1
  end

  it 'works with pattern matching (kind of)' do
    either = Success('ok')

    matched = case either
    when Success; "yeah: #{either.fetch}"
    when Failure; "oh no: #{either.fetch}"
    end

    matched.should == "yeah: ok"
  end

  it 'allows Haskell like syntax' do
    either = Success(1).
      >= { Success(2) }

    either.should == Success(2)
  end

  it 'passes the result value from the previous call to the next' do
    either = Success(1).
      >= {|prev| Success(prev + 1) }.     # a block 
      >= -> prev { Success(prev + 100) }  # lambda/proc

    either.should == Success(102)
  end

  it 'returns the boxed value with the #_ alias for #fetch' do
    Failure(99)._.should == 99
  end

  it 'allows you to use parameterless lambdas (#arity == 0)' do
    (Success(0) >= 
      -> { Success(1) }
    ).should == Success(1)
  end

  it 'allows you to use lambdas with the + operator' do
    either = Success(0) +
      -> { Success(1) } +
      -> { Success(2) }

    either.should == Success(2)
  end

  it 'allows you to use +=' do
    either = Success(0)
    either += -> { Success(1) }

    either.should == Success(1)
  end

  it 'allows to check whether the result was a success or failure' do
    Success(0).success?.should be_true
    Success(1).failure?.should be_false

    Failure(2).success?.should be_false
    Failure(3).failure?.should be_true
  end

  it 'supprts Either.chain' do
    Either.chain do 
      bind -> { Success(1) }
      bind -> { Success(2) }
    end.should == Success(2)

    Either.chain do 
      bind ->    { Success(1)     }
      bind ->(p) { Success(p + 1) }
    end.should == Success(2)

    Either.chain do
      bind { Success(1) }
    end.should == Success(1)
  end

  it 'README example' do
    params = { :path => 'foo' }
    def load_file(path); 
      fail "invalid path" unless path
      Success("bar"); 
    end
    def process_content(content); content.start_with?('b') ? Success(content.upcase) : Failure('invalid content'); end

    either = Either(true).
              bind {          params.fetch(:path)      }.
              bind {|path|    load_file(path)          }.
              bind {|content| process_content(content) }
    either.should be_a_success
    either.fetch.should == 'BAR'

    either = Either(true).
              bind {          {}.fetch(:path)          }.
              bind {|path|    load_file(path)          }.
              bind {|content| process_content(content) }
    either.should be_a_failure
    KeyError.should === either.fetch
  end

  it 'instance variables' do
    result = Either.chain do
      bind { @map = { one: 1, two: 2 } }
      bind { Success(100) }
      bind { @map.fetch(:one) }
      bind { |p| Success(p + 100) }
    end

    result.should == Success(101)
  end
end
