require 'spec_helper'

describe Monadic::Monad do
  it_behaves_like 'a Monad' do 
    let(:monad) { Monad }
  end

  it '#to_s shows the monad name and its value' do
    Monad.unit(1).to_s.should == 'Monad(1)'
    Monad.unit(nil).to_s.should == 'Monad(nil)'
  end
end
