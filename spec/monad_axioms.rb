require 'spec_helper'

shared_examples 'a Monad' do
  describe 'axioms' do
    it '1st monadic law: left-identity' do
      f = ->(value) { monad.unit(value + 1) }
      monad::unit(1).bind do |value|
        f.(value)
      end.should == f.(1)
    end

    it '2nd monadic law: right-identy - unit and bind do not change the value' do
      monad.unit(1).bind do |value|
        monad.unit(value)
      end.should == monad.unit(1)
    end

    it '3rd monadic law: associativity' do
      f = ->(value) { monad.unit(value + 1)   }
      g = ->(value) { monad.unit(value + 100) }

      id1 = monad.unit(1).bind do |a|
        f.(a)
      end.bind do |b|
        g.(b)
      end

      id2 = monad.unit(1).bind do |a|
        f.(a).bind do |b|
          g.(b)
        end
      end

      id1.should == id2
    end
  end
end

