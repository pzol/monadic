require 'monadic'

class AgeTooLowError < ArgumentError;  end
class AgeTooHighError < ArgumentError; end

valid_age = ->(age_expr) {
  age = age_expr.to_i
  case
  when age <=  0; Failure(AgeTooLowError.new(age_expr))
  when age > 130; Failure(AgeTooHighError.new(age_expr))
  else Success(age)
  end
}

valid_name = ->(name) {
  case
  when name =~ /\w{3,99}/i; Success(name)
  else Failure('Invalid name')
  end
}

params = {age: 32, name: 'Andrzej', postcode: '50000'}

Person = Struct.new(:name, :age)

result = Validation() do
  check { valid_name.(params[:name]) }
  check { valid_age.(params[:age])   }
end

case result
  when Failure; puts "Something went wrong: #{result.fetch}"
  when Success; person = Person.new(*result.fetch); puts "We have a person #{person.inspect}"
end

# Failure: Something went wrong: [#<AgeTooHighError: 200>]
# Success: We have a person #<struct Person name="Andrzej", age=32>
