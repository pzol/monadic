require 'spec_helper'

describe Monadic::Either do
  it 'Either cannot be created using #new, use #unit instead' do
    expect { Either.new(1) }.to raise_error NoMethodError
  end

  it 'Success.new and Success.unit and Success() return the same' do
    Success(1).should == Success.unit(1)
    Success.new(1).should == Success.unit(1)

    Success(nil).should == Success.unit(nil)
    Success.new(nil).should == Success.unit(nil)
  end

  it 'Failure.new and Failure.unit and Failure() return the same' do
    Failure(1).should == Failure.unit(1)
    Failure.new(1).should == Failure.unit(1)

    Failure(nil).should == Failure.unit(nil)
    Failure.new(nil).should == Failure.unit(nil)
  end

  it 'Success and Failure should be kind of Either' do
    Success.unit(0).should be_kind_of(Either)
    Failure.unit(0).should be_kind_of(Either)
  end

  it '#to_s works' do
    Success.unit("it worked!").to_s.should == 'Success("it worked!")'
    Failure.unit(nil).to_s.should == "Failure(nil)"
  end

  it 'allows to verify equality' do
    Success(1).should == Success(1)
    Success(2).should_not == Success(1)
    Success(1).should_not == Failure(1)
    Failure(1).should == Failure(1)
    Failure(1).should_not == Failure(2)
  end

  it 'Either(Nothing) is a Failure' do
    Either(Nothing).should == Failure(Nothing)
  end

  it 'wraps a nil result to Failure' do
    Success(nil).bind { nil }.should == Failure(nil)
  end

  it 'catches StandardError exceptions and returns them as Failure' do
    either = Success(nil).
      bind { raise 'error' }

    either.should be_kind_of Failure
    error = either.fetch
    error.should be_kind_of RuntimeError
    error.message.should == 'error'
  end

  it '#or returns an alternative value considered Success if it is Nothing' do
    Failure(false).or(true).should == Failure(true)
    Either(nil).or(true).should == Failure(true)
    Failure(1).or(nil).should == Failure(nil)
    Success(true).or(false).should == Success(true)
    Either(true).or(false).should == Success(true)
    Success(false).or(true).should == Success(false)
  end

  it '#or with a block gets the original value passed' do
    (Failure(1).or { |other| other + 1 }).should == Failure(2)
  end

  class User
    attr :age, :gender, :sobriety
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

  it 'Either on an either returns the Either self to allow coercion' do
    Either(Success(1)).should == Success(1)
    Success(Success(1)).should == Success(1)
    Failure(Failure(1)).should == Failure(1)
  end

  it 'Either with a non-falsey value returns success' do
    Success.should === Either(1)
    Success.should === Either(true)
    Success.should === Either("string")
  end

  it 'works' do
    either = Either(true).
              bind -> { User.find(-1) }
    either.failure?.should be true
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

  it 'allows to add Eithers without specifying a block or proc' do
    (Failure(1) + Failure(2)).should  == Failure(1)
    (Success(1) + Failure(2)).should  == Failure(2)
    (Success(1) + Success(2)).should  == Success(2)
    (Failure(1) >= Failure(2)).should == Failure(1)
    (Success(1) >= Failure(2)).should == Failure(2)
    (Success(1) >= Success(2)).should == Success(2)
  end

  it 'allows to check whether the result was a success or failure' do
    Success(0).success?.should be true
    Success(1).failure?.should be false

    Failure(2).success?.should be false
    Failure(3).failure?.should be true
  end

  it 'supports Either.chain' do
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
    either.fetch.should be_a KeyError
  end

  it 'Either(Nothing) returns a Failure' do
    Either(Nothing).should == Failure(Nothing)
  end

  it 'Either(Just) returns a Success' do
    Either(Just.new(1)).should == Success(1)
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
