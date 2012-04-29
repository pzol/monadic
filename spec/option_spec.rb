require 'spec_helper'

describe 'Option' do 
  it 'nil as value always returns None()' do
     Option(nil).a.b.c.should == None
  end

  it 'None stays None' do
    Option(nil)._.should == None
  end

  it 'None to_s is "None"' do
    option = Option(nil)
    "#{option}".should   == "None"
    "#{option._}".should == "None"
  end

  it '[] as value always returns None()' do
    Option([]).a.should == None
  end

  it 'calling methods on Option always returns an Option with the transformed value' do
    Option('FOO').downcase.should == Some('foo')
  end

  it 'returns the value of an option' do 
    Option('foo').value.should == 'foo'
    Option('foo')._.should == 'foo'
  end

  it 'returns the value of an option with a default, in case value is None' do
    Option(nil).value('bar').should == 'bar'
    Option(nil)._('bar').should == 'bar'
  end

  it 'returns the value and not the default if it is Some' do
    Option('FOO').downcase.value('bar').should == 'foo'
    Option('FOO').downcase._('bar').should == 'foo'
  end

  it 'returns the value applied to a block if it is Some' do
    Option('foo').value('bar') { |val| "You are logged in as #{val}" }.should == 'You are logged in as foo'
    Option(nil).value('You are not logged in') { |val| "You are logged in as #{val}" }.should == 'You are not logged in'
  end

  it 'is never falsey' do
    Option('foo').should_not be_false
    Option(nil).should_not be_false
  end

  it 'tells you if it is none when calling #none?' do
    Option('foo').none?.should be_false
    Option(nil).none?.should be_true
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

  it 'allows to use a block with value and _' do
    user = Option(User.new('foo'))
    user.value('You are not logged in') { |user| "You are logged in as #{user.name}" }.should == 'You are logged in as foo'
  end

  it 'handles (kind-of) falsey values' do
    user = Option(User.new('foo'))
    user.subscribed?.or(false).should be_true
    user.subscribed?.truly?.should be_true

    user = Option(nil)
    user.subscribed?.or(false).should be_false
    user.subscribed?.truly?.should be_false
  end

  it 'allows to use map' do
    Option(nil).map { |e| Hash.new(:key => e) }.should == None
    Option('foo').map { |e| Hash.new(:key => e) }.should == Some(Hash.new(:key => 'foo'))
    Option([1,2]).map { |e| e.to_s }.should == Some(["1", "2"])
  end

  it 'allows to use select' do
    Option('foo').select  { |e| e.start_with?('f') }.should == Some('foo')
    Option('bar').select  { |e| e.start_with?('f') }.should == None
    Option(nil).select    { |e| e.never_called     }.should == None
    Option([1, 2]).select { |e| e == 1             }.should == Some([1])
  end

  it 'acts as an array' do
    Option('foo').to_a.should == ['foo']
    Option(['foo', 'bar']).to_a.should == ['foo', 'bar']
    Option(nil).to_a.should == []
  end

end
