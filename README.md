# Monadic

helps dealing with exceptional situations, it comes from the sphere of functional programming and bringing the goodies I have come to love in Scala to my ruby projects (hence I will be using more Scala like constructs than Haskell).

My motivation to create this gem was that I often work with nested Hashes and need to reach deeply inside of them so my code is sprinkled with things like some_hash.fetch(:one, {}).fetch(:two, {}).fetch(:three, "unknown"). 

We have the following monadics:

- Option (Maybe in Haskell) - Scala like with a rubyesque flavour
- Either - more Haskell like

What's the point of using monads in ruby? To me it started with having a safe way to deal with nil objects and other exceptions.
Thus you contain the erroneous behaviour within a monad - an indivisible, impenetrable unit.

Monad purists might complain that there is no unit method to get the zero monad, I didn't include them, as I didn't find this idiomatic to the ruby language. I prefer to focus on the pragmatic uses of monads. If you want to learn moar about monads, see the references section at the bottom.  

A monad is most effectively described as a computation that eventually returns a value. -- Wolfgang De Meuter

## Usage

### Option
Is an optional type, which helps to handle error conditions gracefully. The one thing to remember about option is: 'What goes into the Option, stays in the Option'. 

    Option(User.find(123)).name._         # ._ is a shortcut for .fetch 

    # if you prefer the alias Maybe instead of option
    Maybe(User.find(123)).name._

    # confidently diving into nested hashes
    Maybe({})[:a][:b][:c]                   == None
    Maybe({})[:a][:b][:c].fetch('unknown')  == None
    Maybe(a: 1)[:a]._                       == 1

Basic usage examples:

    # handling nil (None serves as NullObject)
    obj = nil
    Option(obj).a.b.c            == None

    # None stays None
    Option(nil)._                == "None"
    "#{Option(nil)}"             == "None"
    Option(nil)._("unknown")     == "unknown"
    Option(nil).empty?           == true
    Option(nil).truly?           == false

    # Some stays Some, unless you unbox it
    Option('FOO').downcase       == Some('foo') 
    Option('FOO').downcase.fetch == "foo"
    Option('FOO').downcase._     == "foo"
    Option('foo').empty?         == false
    Option('foo').truly?         == true

Map, select:
    
    Option(123).map   { |value| User.find(value) } == Option(someUser)    # if user found
    Option(0).map     { |value| User.find(value) } == None                # if user not found
    Option([1,2]).map { |value| value.to_s }       == Option(["1", "2"])  # for all Enumerables

    Option('foo').select { |value| value.start_with?('f') } == Some('foo')
    Option('bar').select { |value| value.start_with?('f') } == None

Treat it like an array:

    Option(123).to_a         == [123]
    Option([123, 456]).to_a  == [123, 456]
    Option(nil)              == []

Falsey values (kind-of) examples:

    user = Option(User.find(123))
    user.name._

    user.fetch('You are not logged in') { |user| "You are logged in as #{user.name}" }.should == 'You are logged in as foo'

    if user != nil
      "You are logged in as foo"
    else
      "You are not logged in"

    user.subscribed?              # always true
    user.subscribed?.truly?       # true if subscribed is true
    user.subscribed?.fetch(false) # same as above
    user.subscribed?.or(false)    # same as above

Remember! an Option is never false (in Ruby terms), if you want to know if it is false, call `#empty?` of `#truly?`

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
      Option(title).strip.downcase.tr_s('^[a-z0-9]', '-')._('unknown-title')
    end

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

## Installation

Add this line to your application's Gemfile:

    gem 'monadic'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install monadic

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
