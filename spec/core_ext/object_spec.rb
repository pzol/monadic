require 'spec_helper'
require 'monadic/core_ext/object'

describe 'pseudo Elvis operator _?' do
  it 'works' do
    nil._?.should    == Nothing
    "foo"._?.should  == 'foo'
    {}._?.a.b.should == Nothing
    {}._?[:foo]      == Nothing
    Maybe(nil).fetch_value
  end
end
