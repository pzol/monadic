# Monadic

is a gem to help dealing with exceptional situations, it comes from the sphere of functional programming and bringing the goodies I have come to love in Scala to my ruby projects (hence I will be using more Scala like constructs than Haskell).

See also http://en.wikipedia.org/wiki/Monad

Planned are the following monadics:

- Option (Maybe in Haskell)
- Either *planned

## Installation

Add this line to your application's Gemfile:

    gem 'monadic'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install monadic

## Usage

### Option
Is an optional type, which helps to handle error conditions gracefully. The one thing to remember about option is: 'What goes into the Option, stays in the Option'.

Basic usage examples:

    # handling nil (None serves as NullObject)
    obj = nil
    Option(obj).a.b.c            == None

    # None stays None
    Option(nil)._             == "None"
    "#{Option(nil)}"          == "None"
    Option(nil)._("unknown")  == "unknown"

    Option('FOO').downcase       == Some('foo') 
    Option('FOO').downcase.value == "foo"
    Option('FOO').downcase._     == "foo"

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

Remember! an Option is never falsey, if you want to know if it is false, call `#none?`

    user = Option(User.find(123))
    user.value('You are not logged in') { |user| "You are logged in as #{user.name}" }.should == 'You are logged in as foo'

    if user != nil
      "You are logged in as foo"
    else
      "You are not logged in"

    user.subscribed?              # always true
    user.subscribed?.truly?       # true if subscribed is true
    user.subscribed?.value(false) # same as above
    user.subscribed?.or(false)    # same as above

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


see also [Option Type ](http://devblog.avdi.org/2011/05/30/null-objects-and-falsiness/) and 
[NullObject and Falsiness by @avdi](http://devblog.avdi.org/2011/05/30/null-objects-and-falsiness/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
