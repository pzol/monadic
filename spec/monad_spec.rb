require 'spec_helper'

describe Monadic::Monad do
  it '1st monadic law: left-identity' do
    f = ->(value) { Monad.unit(value + 1) }
    Monad::unit(1).bind do |value|
      f.(value)
    end.should == f.(1)
  end

  it '2nd monadic law: right-identy - unit and bind do not change the value' do
    Monad.unit(1).bind do |value|
      Monad.unit(value)
    end.should == Monad.unit(1)
  end

  it '3rd monadic law: associativity' do 
    f = ->(value) { Monad.unit(value + 1)   }
    g = ->(value) { Monad.unit(value + 100) }    

    id1 = Monad.unit(1).bind do |a|
      f.(a)
    end.bind do |b| 
      g.(b) 
    end

    id2 = Monad.unit(1).bind do |a|
      f.(a).bind do |b|
        g.(b)
      end
    end

    id1.should == id2
  end

  it '#to_s shows the monad name and its value' do
    Monad.unit(1).to_s.should == 'Monad(1)'
    Monad.unit(nil).to_s.should == 'Monad(nil)'
  end
end
