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

  describe '#map functor' do
    add100 = ->(value) { value + 100 }
    it 'on value types, returns the transformed value, wrapped in the Monad' do
      res = monad.unit(1).map {|v| add100.(v) }
      res.should == monad.unit(101)

      res = monad.unit(1).map {|v| monad.unit(v + 100) }
      res.should == monad.unit(101)
    end

    it 'on enumerables, returns the transformed collection, wrapped in the Monad' do
      res = monad.unit([1,2,3]).map {|v| add100.(v) }
      res.should == monad.unit([101,102,103])

      # The following does not work... not sure whether it should
      # res = monad.unit([1,2,3]).map {|v| monad.unit(v + 100) }
      # res.should == monad.unit([101,102,103])
    end
  end
end
