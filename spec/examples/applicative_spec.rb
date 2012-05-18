require 'spec_helper'

# Is a transformation C[A -> B]  ->  C[A] -> C[B]
module Applicative
  # @param [Proc, lambda] proc
  # @return [Functor] functor
  def apply(value)
    return value.class.unit(@value.call(value.fetch))
  end
  alias :<< :apply
end

class Maybe
  include Applicative
end

class Either
  include Applicative
end


describe Applicative do
  it 'allows applying monads' do
    l = lambda {|x,y| x + y }.curry
    res = Just(l) << Just(1) << Just(3)
    res.should == Just(4)
  end

  it 'applicative composition success' do 
    settings  = ->     { Success({setting: 1}) }
    db        = ->(pr) { [pr, :x, :y, ] }
    ws        = ->(pr) { "Rock'n'Roll #{pr}" }
    construct = ->(preferences, database, webservice) { "#{preferences} #{database} #{webservice}" }.curry

    res = Either(construct) >= settings >= db >= ws
    res.should == Success("Rock'n'Roll [{:setting=>1}, :x, :y]")
  end

  it 'applicative composition failure' do
    settings  = ->     { Success({a: 1}) }
    db        = ->(pr) { Failure('too many connections') }
    ws        = ->(pr) { raise 'should have never called me' }
    construct = ->(preferences, database, webservice) { "never executed" }.curry

    res = Either(construct) + settings + db + ws
    res.should == Failure('too many connections')
  end
end
