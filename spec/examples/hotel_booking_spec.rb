require 'spec_helper'
require 'active_support/time'

describe 'Hotel Booking Example' do

  class Request < Struct
    def self.create(params, params_module)
      value = self.create_value(params || {}, params_module)

      if value.values.all?(&:success?)
        Success(value)
      else
        Failure(value)
      end
    end

    def to_hash
      Hash[*members.zip(values).flatten]
    end

    def unwrap
      Struct.new(*members).new(*values.map(&:fetch))
      # self.class.new(*values.map(&:fetch))
    end

    private
    def self.create_value(params, params_module)
      properties = params_module.methods - Module.methods
      request_klas = self.new(*properties)
      properties.reduce(request_klas.new) do |request, property|
        request[property] = params_module.send(property, params)
        request
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

    VALID_ROOM_TYPE = %w[SR DR TR QR]
    def room_type(params)
      case value = params['room_type']
      when nil
        Failure('room_type must not be empty')
      when is_valid_room_type
        Success(value)
      else
        Failure("room_type '#{value}' must be one of #{VALID_ROOM_TYPE.join(', ')}")
      end
    end

    def check_in(params)
      param = params['check_in']
      return Failure("check_in must not be empty")    if param.nil?
      return Try { Date.parse(param) }.else {|e| "check_in #{e.message} '#{param}'" }
    end

    private
    def is_valid_room_type
      Object.new.tap {|matcher|
        def matcher.===(value)
          VALID_ROOM_TYPE.include? value
        end
      }
    end
  end

  let(:params_proto) do
    {'hotel_code'  => 'STO0001',
     'check_in'    => '2012-06-15',
     'nights'      => '3',
     'room_type'   => 'DR',
     'guest1'      => 'Max Payne',
     'guest2'      => 'Jenny Payne'}
  end

  it 'builds a valid request' do
    result = Request.create(params_proto, HotelBookingRequestParams)
    result.should be_a Success
    request = result.fetch.unwrap
    request.hotel_code.should eq "STO0001"
    request.nights.should eq 3
  end

  it 'reports an invalid room_type' do
    params = params_proto.merge 'room_type' => 'XX'
    result = Request.create(params, HotelBookingRequestParams)
    result.should be_a Failure
    request = result.fetch
    request.room_type.should be_a Failure
  end

  it 'reports an invalid check_in time' do
    params = params_proto.merge 'check_in' => '2012-11-31'
    result = Request.create(params, HotelBookingRequestParams)
    result.should be_a Failure
    request = result.fetch
    request.check_in.should be_a Failure
    request.check_in.should == Failure("check_in invalid date '2012-11-31'")
  end

  it 'builds a failure request with no params' do
    result = Request.create(nil, HotelBookingRequestParams)
    result.should be_a Failure
    request = result.fetch
    request.hotel_code.should be_a Failure
    request.nights.should be_a Failure
    request.room_type.should be_a Failure
    request.check_in.should be_a Failure
  end

end
