require 'spec_helper'

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

describe Monadic::Maybe do
  it 'works' do
    # Maybe(1)
  end

  it '1st monadic law: left-identity' do
    f = ->(value) { Just.unit(value + 1) }
    Just::unit(1).bind do |value|
      f.(value)
    end.should == f.(1)
  end

  it '2nd monadic law: right-identy - unit and bind do not change the value' do
    Just.unit(1).bind do |value|
      Just.unit(value)
    end.should == Just.unit(1)
  end

  it '3rd monadic law: associativity' do 
    f = ->(value) { Just.unit(value + 1)   }
    g = ->(value) { Just.unit(value + 100) }    

    id1 = Just.unit(1).bind do |a|
      f.(a)
    end.bind do |b| 
      g.(b) 
    end

    id2 = Just.unit(1).bind do |a|
      f.(a).bind do |b|
        g.(b)
      end
    end

    id1.should == id2
  end 

  it 'Maybe cannot be created using #new, use #unit instead' do
    expect { Maybe.new(1) }.to raise_error NoMethodError
  end 

  it 'nil as value always returns Nothing()' do
     Maybe(nil).a.b.c.should == Nothing
  end

  it 'Nothing stays Nothing' do
    expect { Maybe(nil).fetch }.to raise_error Monadic::NoValueError
    Maybe(nil).empty?.should be_true
  end  

  it 'Just stays Just' do
    Maybe('foo').should be_kind_of(Just) 
    Maybe('foo').empty?.should be_false
  end

  it 'Just#to_s is "Just(value)"' do
    Just.unit(123).to_s.should == "Just(123)"
  end

  it 'Nothing#to_s is "Nothing"' do
    option = Maybe(nil)
    "#{option}".should   == "Nothing"
  end

  it 'Nothing is always empty' do
    Nothing.empty?.should be_true
    Maybe(nil).empty?.should be_true
  end

  it '[] as value always returns Nothing()' do
    Maybe([]).a.should == Nothing
  end

  it 'calling methods on Maybe always returns an Maybe with the transformed value' do
    Maybe('FOO').downcase.should == Just('foo') 
  end

  it '#fetch returns the value of an option' do 
    Maybe('foo').fetch.should == 'foo'
    Maybe('foo')._.should == 'foo'
  end

  it 'returns the value of an option with a default, in case value is Nothing' do
    Maybe(nil).fetch('bar').should == 'bar'
    Maybe(nil)._('bar').should == 'bar'
  end

  it 'returns the value and not the default if it is Just' do
    Maybe('FOO').downcase.fetch('bar').should == 'foo'
    Maybe('FOO').downcase._('bar').should == 'foo'
  end

  it 'is never falsey' do
    Maybe('foo').should_not be_false
    Maybe(nil).should_not be_false
  end


  class User 
    attr_reader :name
    def initialize(name)
      @name = name
    end
    def subscribed?
      true
    end
  end

  it 'handles (kind-of) falsey values' do
    user = Maybe(User.new('foo'))
    user.subscribed?.fetch(false).should be_true
    user.subscribed?.truly?.should be_true

    user = Maybe(nil)
    user.subscribed?.fetch(false).should be_false
    user.subscribed?.truly?.should be_false
  end

  it 'allows to use map' do
    Maybe(nil).map { |e| Hash.new(:key => e) }.should == Nothing
    Maybe('foo').map { |e| Hash.new(:key => e) }.should == Just(Hash.new(:key => 'foo'))
    Maybe([1,2]).map { |e| e.to_s }.should == Just(["1", "2"])
  end

  it 'allows to use select' do
    Maybe('foo').select  { |e| e.start_with?('f') }.should == Just('foo')
    Maybe('bar').select  { |e| e.start_with?('f') }.should == Nothing
    Maybe(nil).select    { |e| e.never_called     }.should == Nothing
    Maybe([1, 2]).select { |e| e == 1             }.should == Just([1])
  end

  it 'acts as an array' do
    Maybe('foo').to_a.should == ['foo']
    Maybe(['foo', 'bar']).to_a.should == ['foo', 'bar']
    Maybe(nil).to_a.should == []
  end

  it 'diving into hashes' do
    Maybe({})['a']['b']['c'].should == Nothing
    Maybe({a: 1})[:a]._.should == 1
  end

  it 'should support Rumonades example' do
    require 'active_support/time'
    def format_date_in_march(time_or_date_or_nil)
    Maybe(time_or_date_or_nil).    # wraps possibly-nil value in an Maybe monad (Some or Nothing)
      map(&:to_date).               # transforms a contained Time value into a Date value
      select {|d| d.month == 3}.    # filters out non-matching Date values (Some becomes Nothing)
      map(&:to_s).                  # transforms a contained Date value into a String value
      map {|s| s.gsub('-', '')}.    # transforms a contained String value by removing '-'
      fetch("not in march!")        # returns the contained value, or the alternative if Nothing
    end

    format_date_in_march(nil).should == "not in march!"
    format_date_in_march(Time.parse('2009-01-01 01:02')).should == "not in march!"
    format_date_in_march(Time.parse('2011-03-21 12:34')).should == "20110321"    
  end

end
