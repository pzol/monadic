require 'spec_helper'

describe Monadic::Monad do
  it_behaves_like 'a Monad' do 
    let(:monad) { Monad }
  end

  it '#to_s shows the monad name and its value' do
    Monad.unit(1).to_s.should == 'Monad(1)'
    Monad.unit(nil).to_s.should == 'Monad(nil)'
    Monad.unit([1, 2]).map(&:to_s).should == Monad.unit(["1", "2"])

    # can be done also
    Monad.unit([1, 2]).bind {|v| Monad.unit(v.map(&:to_s)) }.should == Monad.unit(["1", "2"])
  end

  describe '#map' do
    it 'applies the function to the underlying value directly' do
      Monad.unit(1).map {|v| v + 2}.should == Monad.unit(3)
      Monad.unit('foo').map(&:upcase).should == Monad.unit('FOO')
    end

    it 'delegates #map to an underlying collection and wraps the resulting collection' do
      Monad.unit([1,2]).map {|v| v + 1}.should == Monad.unit([2, 3])
      Monad.unit(['foo', 'bar']).map(&:upcase).should == Monad.unit(['FOO', 'BAR'])
    end
  end

  describe '#to_ary #to_a' do
    Monad.unit([1, 2]).to_a.should == [1, 2]
    Monad.unit(nil).to_a.should == []
    Monad.unit('foo').to_a.should == ['foo']
  end
end
