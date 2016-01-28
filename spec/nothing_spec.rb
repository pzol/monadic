require 'spec_helper'

 describe Monadic::Nothing do
    it_behaves_like 'a Monad' do
      let(:monad) { Nothing }
    end

    it '===' do
      (Maybe(nil) === Nothing).should be true
    end

    it 'is empty' do
      Maybe(nil).empty?.should be true
    end

    it 'returns Nothing' do
      Maybe(nil).fetch.should == Nothing
      Maybe(nil)._.should == Nothing
    end

    it 'fetches a nil value' do
      Maybe(nil).fetch(nil).should == nil
      Maybe(nil)._(nil).should == nil
      Maybe(nil)._('').should == ''
    end

    it 'Nothing#to_s is "Nothing"' do
      option = Maybe(nil)
      "#{option}".should   == "Nothing"
      Nothing.to_s.should == "Nothing"
      Nothing.to_s(1, 2).should == "Nothing"
    end

    it 'Nothing#to_json is nil' do
      Maybe(nil).to_json(:only => :a).should == 'null'
      Nothing.to_json.should == 'null'
    end

    it 'Nothing is always empty' do
      Nothing.empty?.should be true
      Maybe(nil).empty?.should be true
    end

    it '[] as value always returns Nothing()' do
      Maybe([]).a.should == Nothing
    end

    it 'is always empty and false' do
      Nothing.empty?.should be true
      Nothing.truly?.should be false
    end

    it 'returns Nothing when calling #name' do
      hd = Nothing
      hd.name.should == Monadic::Nothing
    end

    it 'Nothing#or returns the alternative' do
      Maybe(nil).or(1).should == Just(1)
      Nothing.or(1).should == Just(1)
      Nothing.or(Just(nil)).should == Just(nil)
      Nothing.something.or(1).should == Just(1)
      Nothing.something.or(Just(nil)).should == Just(nil)
      Nothing.or('').should == Just('')
    end
  end
