# Monadic
[![Build Status](https://secure.travis-ci.org/pzol/monadic.png?branch=master)](http://travis-ci.org/pzol/monadic) 

helps dealing with exceptional situations, it comes from the sphere of functional programming and bringing the goodies I have come to love in [Scala](http://www.scala-lang.org/) and [Haskell](http://www.haskell.org/) to my ruby projects.

My motivation to create this gem was that I often work with nested Hashes and need to reach deeply inside of them so my code is sprinkled with things like some_hash.fetch(:one, {}).fetch(:two, {}).fetch(:three, "unknown"). 

We have the following monadics (monads, functors, applicatives and variations):

- Maybe  - use if you have __one__  exception
- Either - use if you have __many__ exceptions, and one call depends on the previous
- Validation - use if you have __many__ independent calls (usually to validate an object)

What's the point of using monads in ruby? To me it started with having a safe way to deal with nil objects and other exceptions.
Thus you contain the erroneous behaviour within a monad - an indivisible, impenetrable unit. Functional programming considers _throwing_ exceptions to be a side-effect, instead we _propagate_ exceptions, i.e. return them as a result of a function call.
 
A monad is most effectively described as a computation that eventually returns a value. -- Wolfgang De Meuter

## Usage

### Maybe
Most people probably will be interested in the Maybe monad, as it solves the problem with nil invocations, similar to [andand](https://github.com/raganwald/andand) and others.

Maybe is an optional type, which helps to handle error conditions gracefully. The one thing to remember about option is: 'What goes into the Maybe, stays in the Maybe'. 

    Maybe(User.find(123)).name._         # ._ is a shortcut for .fetch 

    # if you prefer the alias Maybe instead of option
    Maybe(User.find(123)).name._

    # confidently diving into nested hashes
    Maybe({})[:a][:b][:c]                   == Nothing
    Maybe({})[:a][:b][:c].fetch('unknown')  == "unknown"
    Maybe(a: 1)[:a]._                       == 1

Basic usage examples:

    # handling nil (None serves as NullObject)
    Maybe(nil).a.b.c            == Nothing

    # Nothing
    Maybe(nil)._                == Nothing
    "#{Maybe(nil)}"             == "Nothing"
    Maybe(nil)._("unknown")     == "unknown"
    Maybe(nil).empty?           == true
    Maybe(nil).truly?           == false

    # Just stays Just, unless you unbox it
    Maybe('FOO').downcase       == Just('foo') 
    Maybe('FOO').downcase.fetch == "foo"          # unboxing the value
    Maybe('FOO').downcase._     == "foo"          
    Maybe('foo').empty?         == false          # always non-empty
    Maybe('foo').truly?         == true           # depends on the boxed value
    Maybe(false).empty?         == false
    Maybe(false).truly?         == false

Map, select:
    
    Maybe(123).map   { |value| User.find(value) } == Just(someUser)      # if user found
    Maybe(0).map     { |value| User.find(value) } == Nothing             # if user not found
    Maybe([1,2]).map { |value| value.to_s }       == Just(["1", "2"])    # for all Enumerables

    Maybe('foo').select { |value| value.start_with?('f') } == Just('foo')
    Maybe('bar').select { |value| value.start_with?('f') } == Nothing

Treat it like an array:

    Maybe(123).to_a          == [123]
    Maybe([123, 456]).to_a   == [123, 456]
    Maybe(nil).to_a          == []

Falsey values (kind-of) examples:

    user = Maybe(User.find(123))
    user.name._

    user.subscribed?              # always true
    user.subscribed?.truly?       # true if subscribed is true
    user.subscribed?.fetch(false) # same as above
    user.subscribed?.or(false)    # same as above

Remember! a Maybe is never false (in Ruby terms), if you want to know if it is false, call `#empty?` of `#truly?`

`#truly?` will return true or false, always.

Slug example

    # instead of 
    def slug(title)
      if title
        title.strip.downcase.tr_s('^[a-z0-9]', '-')
      end
    end

    # or 

    def slug(title)
      title && title.strip.downcase.tr_s('^[a-z0-9]', '-')
    end

    # do it with a default
    def slug(title)
      Maybe(title).strip.downcase.tr_s('^[a-z0-9]', '-')._('unknown-title')
    end

### Object#_?
Works similar to the Elvis operator _? - ruby does not allow ?: as operator and use it like the excellent [andand](https://github.com/raganwald/andand)

    require 'monadic/core_ext/object'   # this will import _? into the global Object
    nil._?           == Nothing
    "foo"._?         == 'foo'
    {}._?.a.b        == Nothing
    {}._?[:foo]      == Nothing

In fact this is a shortcut notation for `Maybe(obj)`

### Either
Its main purpose here to handle errors gracefully, by chaining multiple calls in a functional way and stop evaluating them as soon as the first fails.
Assume you need several calls to construct some object in order to be useful, after each you need to check for success. Also you want to catch exceptions and not let them bubble upwards.  
What is specific to this implementation is that exceptions are caught within the execution blocks. This way I have all error conditions wrapped in one place.

`Success` represents a successfull execution of an operation (Right in Scala, Haskell).  
`Failure` represents a failure to execute an operation (Left in Scala, Haskell).  

The `Either()` wrapper will treat all falsey values `nil`, `false` or `empty?` as a `Failure` and all others as `Success`. If that does not suit you, use `Success` or `Failure` only.

    result = parse_and_validate_params(params).                 # must return a Success or Failure inside
                bind ->(user_id) { User.find(user_id) }.        # if #find returns null it will become a Failure
                bind ->(user)    { authorized?(user); user }.   # if authorized? raises an Exception, it will be a Failure 
                bind ->(user)    { UserDecorator(user) }

    if result.success?
      @user = result.fetch                                      # result.fetch or result._ contains the 
      render 'page'
    else
      @error = result.fetch
      render 'error_page'
    end

You can use alternate syntaxes to achieve the same goal:

    # block and Haskell like >= operator
    Either(operation).
      >= { successful_method }.
      >= { failful_operation }

    # start with a Success, for instance a parameter
    Success('pzol').
      bind ->(previous) { good }.
      bind ->           { bad  }

    Either.chain do
      bind ->                   { good   }                     # >= is not supported for Either.chain, only bind
      bind ->                   { better }                     # better returns Success(some_int)
      bind ->(previous_result)  { previous_result + 1 }
    end

    either = Either(something)
    either += truth? Success('truth, only the truth') : Failure('lies, damn lies')

Exceptions are wrapped into a Failure:

    Either(true).
      bind -> { fail 'get me out of here' }                    # return a Failure(RuntimeError)

Another example:

    Success(params).
      bind ->(params)   { Either(params.fetch(:path)) }        # fails if params does not contain :path
      bind ->(path)     { load_stuff(params)          }        # 

Storing intermediate results in instance variables is possible, although it is not very elegant:

    result = Either.chain do
      bind { @map = { one: 1, two: 2 } }
      bind { @map.fetch(:one) }
      bind { |p| Success(p + 100) }
    end

    result == Success(101)


### Validation 
The Validation applicative functor, takes a list of checks within a block. Each check must return either Success of Failure.  
If Successful, it will return Success, if not a Failure monad, containing a list of failures.  
Within the Failure() provide the reason why the check failed.

Example:

    def validate(person)
      check_age = ->(age_expr) {
        age = age_expr.to_i
        case 
        when age <=  0; Failure('Age must be > 0')
        when age > 130; Failure('Age must be < 130')
        else Success(age)
        end
      }

      check_sobriety = ->(sobriety) {
        case sobriety
        when :sober, :tipsy; Success(sobriety)
        when :drunk        ; Failure('No drunks allowed')
        else Failure("Sobriety state '#{sobriety}' is not allowed")
        end 
      }

      check_gender = ->(gender) {
        gender == :male || gender == :female ? Success(gender) : Failure("Invalid gender #{gender}")
      }
        
      Validation() do
        check { check_age.(person.age);          }
        check { check_sobriety.(person.sobriety) }
        check { check_gender.(person.gender)     }
      end
    end

The above example, returns either `Success([32, :sober, :male])` or `Failure(['Age must be > 0', 'No drunks allowed'])` with a list of what went wrong during the validation.

See also [examples/validation.rb](https://github.com/pzol/monadic/blob/master/examples/validation.rb) and [examples/validation_module](https://github.com/pzol/monadic/blob/master/examples/validation_module.rb) 

### Monad 
All Monads inherit from this class. Standalone it is an Identity monad. Not useful on its own. It's methods are usable on all its descendants.

__#map__ is used to map the inner value

    Monad.unit('FOO').map(&:capitalize).map {|v| "Hello #{v}"}    == Monad(Hello Foo)
    Monad.unit([1,2]).map {|v| v + 1}                             == Monad([2, 3])

__#bind__ allows (priviledged) access to the boxed value. This is the traditional _no-magic_ `#bind` as found in Haskell, 
You are responsible for re-wrapping the value into a Monad again.
  
    # due to the way it works, it will simply return the value, don't rely on this though, different Monads may
    # implement bind differently (e.g. Maybe involves some _magic_)
    Monad.unit('foo').bind(&:capitalize)                          == Foo

    # proper use
    Monad.unit('foo').bind {|v| Monad.unit(v.capitalize) }        == Monad(Foo)

__#fetch__ extracts the inner value of the Monad, some Monads will override this standard behaviour, e.g. the Maybe Monad

    Monad.unit('foo').fetch                                       == "foo"

## References

 * [Wikipedia Monad](See also http://en.wikipedia.org/wiki/Monad)
 * [Learn You a Haskell - for a few monads more](http://learnyouahaskell.com/for-a-few-monads-more)
 * [Monad equivalent in Ruby](http://stackoverflow.com/questions/2709361/monad-equivalent-in-ruby)
 * [Option Type ](http://devblog.avdi.org/2011/05/30/null-objects-and-falsiness/)
 * [NullObject and Falsiness by @avdi](http://devblog.avdi.org/2011/05/30/null-objects-and-falsiness/)
 * [andand](https://github.com/raganwald/andand/blob/master/README.textile)
 * [ick](http://ick.rubyforge.org/)
 * [Monads in Ruby](http://moonbase.rydia.net/mental/writings/programming/monads-in-ruby/00introduction.html)
 * [The Maybe Monad in Ruby](http://pretheory.wordpress.com/2008/02/14/the-maybe-monad-in-ruby/)
 * [Monads in Ruby with nice syntax](http://www.valuedlessons.com/2008/01/monads-in-ruby-with-nice-syntax.html)
 * [Maybe in Ruby](https://github.com/bhb/maybe)
 * [Monads on the Cheap](http://osteele.com/archives/2007/12/cheap-monads)
 * [Rumonade - another excellent (more scala-like) monad implementation](https://github.com/ms-ati/rumonade)
 * [Monads for functional programming](http://homepages.inf.ed.ac.uk/wadler/papers/marktoberdorf/baastad.pdf)
 * [Monads as a theoretical foundation for AOP](http://soft.vub.ac.be/Publications/1997/vub-prog-tr-97-10.pdf)
 * [What is an applicative functor?](http://applicative-errors-scala.googlecode.com/svn/artifacts/0.6/html/index.html)

## Installation

Add this line to your application's Gemfile:

    gem 'monadic'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install monadic

## Compatibility
Monadic is tested under ruby MRI 1.9.2, 1.9.3, jruby 1.9 mode, rbx 1.9 mode.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
