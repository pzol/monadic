require 'monadic'

valid_age = ->(age_expr) {
  age = age_expr.to_i
  case 
  when age <=  0; Failure('Age must be > 0')
  when age > 130; Failure('Age must be < 130')
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
  check { valid_age.(params[:age])   }
  check { valid_name.(params[:name]) }
end

case result
  when Failure; puts "Something went wrong: #{result.fetch}"
  when Success; person = Person.new(*result.fetch); puts "We have a person #{person.inspect}"
end
