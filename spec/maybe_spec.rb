require 'spec_helper'

describe Monadic::Maybe do
  it_behaves_like 'a Monad' do
    let(:monad) { Maybe }
  end

  it 'Maybe cannot be created using #new, use #unit instead' do
    expect { Maybe.new(1) }.to raise_error NoMethodError
  end 

  it 'nil as value always returns Nothing()' do
     Maybe(nil).a.b.c.should == Nothing
  end

  describe Monadic::Nothing do
    it_behaves_like 'a Monad' do
      let(:monad) { Nothing }
    end

    it 'Nothing stays Nothing' do
      expect { Maybe(nil).fetch }.to raise_error Monadic::NoValueError
      Maybe(nil).empty?.should be_true
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
  end

  describe Monadic::Just do
    it_behaves_like 'a Monad' do
      let(:monad) { Just }
    end

    it 'Just stays Just' do
      Maybe('foo').should be_kind_of(Just) 
      Maybe('foo').empty?.should be_false
    end

    it 'Just#to_s is "Just(value)"' do
      Just.unit(123).to_s.should == "Just(123)"
    end
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

  it 'handles (kind-of) falsey values' do
    FalseyUser = Struct.new(:name, :subscribed)
    user = Maybe(FalseyUser.new(name = 'foo', subscribed = true))
    user.subscribed.fetch(false).should be_true
    user.subscribed.truly?.should be_true

    user = Maybe(nil)
    user.subscribed.fetch(false).should be_false
    user.subscribed.truly?.should be_false
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
