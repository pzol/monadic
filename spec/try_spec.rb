require 'spec_helper'

describe 'Monadic::Try' do
  it 'catches exceptions' do
    Try { Date.parse('2012-02-30') }.should be_a Failure
  end

  it 'returns Failure when the value is nil or false' do
    Try { nil }.should be_a Failure
    Try { false }.should be_a Failure
  end

  it 'returns Failure for an empty collection' do
    Try { [] }.should be_a Failure
  end

  it 'with a param, without a block it returns the predicate' do
    Try(true).should be_a Success
    Try(false).should be_a Failure
    Try(nil).should be_a Failure
  end

  it 'with a param and with a block it returns the block result' do
    Try(true)  { 1 }.should == Success(1)
    Try(false) { 2 }.should == Failure(2)
    Try(false) { 1 }.else { 2 }.should == Failure(2)
  end

  it 'with a proc and no block it evaluates the proc' do
    Try(-> { 1 }).should == Success(1)
    Try(-> { 1 }) { 2 }.should == Success(2)
  end

  it 'no params is the same as passing nil as the predicatea' do
    Try().should == Failure(nil)
  end

  it 'returns Success for non-nil values' do
    Try { 1 }.should == Success(1)
    Try { "string" }.should == Success("string")
  end

  it 'combined with else and a block' do
    Try { Date.parse('2012-02-30') }.else {|e| "Exception: #{e.message}" }.should == Failure("Exception: invalid date")
    Try { Date.parse('2012-02-28') }.else {|e| "Exception: #{e.message}" }.should == Success(Date.parse('2012-02-28'))
  end
end
