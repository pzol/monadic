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

  it 'without a block it works like Either' do
    Try(true).should be_a Success
    Try(false).should be_a Failure
    Try(nil).should be_a Failure
  end

  it 'with a proc' do
    pending
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
