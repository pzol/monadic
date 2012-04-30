require 'monadic/version'

$LOAD_PATH << File.expand_path('..', __FILE__)

require 'monadic/errors'
require 'monadic/option'

module Monadic
end

include Monadic
None = Monadic::None
Some = Monadic::Some
