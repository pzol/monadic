require 'spec_helper'
require 'active_support/time'

describe 'Hotel Booking Example' do

   module Request
    def self.create(params, params_module)
      value = self.create_value(params || {}, params_module)

      if value.values.all?(&:success?)
        Success(value)
      else
        Failure(value)
      end
    end

    private
    def self.create_value(params, params_module)
      properties = params_module.methods - Module.methods
      request = Struct.new(*properties)
      properties.reduce(request.new) do |container, property|
        container[property] = params_module.send(property, params)
        container
      end
    end
  end

  module HotelBookingRequestParams
    extend self

    def hotel_code(params)
      value = params['hotel_code']
      case
      when value.nil?
        Failure('hotel_code must not be empty')
      when not(value =~ /^[A-Z]{3}[A-Z0-9]{4}$/)
        Failure('hotel_code must be of pattern XXX0001')
      else
        Success(value)
      end
    end

    def nights(params)
      value = params.fetch('nights', 0).to_i
      if value <= 0
        Failure("nights must be a number greater than 0 (got '#{params['nights']}')")
      else
        Success(value)
      end
    end

    def room_type(params)
      case value = params['room_type']
      when nil
        Failure('room_type must not be empty')
      else 
        Success(value)
      end
    end
  end

  class Struct
    def to_hash
      Hash[*members.zip(values).flatten]
    end

    def unwrap
      self.class.new(*values.map(&:fetch))
    end
  end

  it 'builds a valid request' do
    params = {'hotel_code' => 'STO0001',
     'check_in'   => '2012-06-15',
     'nights'     => '3',
     'room_type'  => 'DR',
     'guest1'     => 'Max Payne',
     'guest2'     => 'Jenny Payne'}
    request = Request.create(params, HotelBookingRequestParams)
    request.should be_a Success
    value = request.fetch.unwrap
    value.hotel_code.should eq "STO0001"
    value.nights.should eq 3
  end

  it 'builds a failure request with no params' do
    request = Request.create(nil, HotelBookingRequestParams)
    request.should be_a Failure
    value = request.fetch
    value.hotel_code.should be_a Failure
    value.nights.should be_a Failure
    value.room_type.should be_a Failure
  end

end
