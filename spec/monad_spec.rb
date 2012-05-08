require 'spec_helper'

describe Monadic::Monad do
  class Identity 
    include Monadic::Monad
    def self.unit(value)
      new(value)
    end
  end

  it_behaves_like 'a Monad' do 
    let(:monad) { Identity }
  end

  it '#to_s shows the monad name and its value' do
    Identity.unit(1).to_s.should == 'Identity(1)'
    Identity.unit(nil).to_s.should == 'Identity(nil)'
    Identity.unit([1, 2]).map(&:to_s).should == Identity.unit(["1", "2"])

    # can be done also
    Identity.unit([1, 2]).bind {|v| Identity.unit(v.map(&:to_s)) }.should == Identity.unit(["1", "2"])
  end

  describe '#map' do
    it 'applies the function to the underlying value directly' do
      Identity.unit(1).map {|v| v + 2}.should == Identity.unit(3)
      Identity.unit('foo').map(&:upcase).should == Identity.unit('FOO')
    end

    it 'delegates #map to an underlying collection and wraps the resulting collection' do
      Identity.unit([1,2]).map {|v| v + 1}.should == Identity.unit([2, 3])
      Identity.unit(['foo', 'bar']).map(&:upcase).should == Identity.unit(['FOO', 'BAR'])
    end
  end

  describe '#to_ary #to_a' do
    Identity.unit([1, 2]).to_a.should == [1, 2]
    Identity.unit(nil).to_a.should == []
    Identity.unit('foo').to_a.should == ['foo']
  end
end
