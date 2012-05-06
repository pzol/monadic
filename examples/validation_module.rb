require 'monadic'

Person = Struct.new(:name, :age)

module PersonValidation
  class AgeTooLowError < ArgumentError;  end
  class AgeTooHighError < ArgumentError; end

  def self.validate(params)
    Validation()  do
      extend PersonValidation
      check { valid_age(params[:age])  }
      check { valid_name(params[:name])}
    end
  end

  def valid_age(expr)
    age = expr.to_i
    case 
    when expr.nil?; Failure(ArgumentError.new(:age))
    when age <=  0; Failure(AgeTooLowError.new(expr))
    when age > 130; Failure(AgeTooHighError.new(expr))
    else Success(age)
    end
  end

  def valid_name(name)
    case 
    when name =~ /\w{3,99}/i; Success(name)
    else Failure('Invalid name')
    end
  end
end

module PersonBuild
  def self.build(params)
    result = PersonValidation.validate(params)
    case result
    when Failure; result
    when Success; Person.new(*result.fetch)
    end
  end
end

p person1 = PersonBuild.build({ name: 'Andrzej' })            # Failure([#<ArgumentError: age>])
p person2 = PersonBuild.build({ name: 'Andrzej', age: 32 })   # <struct Person name=32, age="Andrzej">
