require 'spec_helper'
require 'active_support/time'

describe 'Hotel Booking Example' do
  module HotelBookingRequestParams
    extend self

    def hotel_code(params)
      param = params['hotel_code']
      Try(param =~ /^[A-Z]{3}[A-Z0-9]{4}$/) { param }.or "hotel_code must be of pattern XXX0001, got '#{param}'"
    end

    def nights(params)
      value = params.fetch('nights', 0).to_i
      Try(value > 0) { value }.or "nights must be a number greater than 0, got '#{params['nights']}'"
    end

    ROOM_OCCUPANCIES = {'SR' => 1, 'DR' => 2, 'TR' => 3, 'QR' => 4 }
    VALID_ROOM_TYPES = ROOM_OCCUPANCIES.keys
    def room_type(params)
      param = params['room_type']
      Try(VALID_ROOM_TYPES.include?(param)) { param }.or "room_type must be one of '#{VALID_ROOM_TYPES.join(', ')}', got '#{param}'"
    end

    def check_in(params)
      param = params['check_in']
      Try { Date.parse(param) }.or {|e| "check_in #{e.message}, got '#{param}'" }
    end

    OCCUPANCIES = [1, 2, 3, 4]
    def guests(params)
      guests    = params.select {|p| p =~ /^guest/ }.values.compact
      rt        = params['room_type']
      occupancy = ROOM_OCCUPANCIES.fetch(rt, 99)
      Try(guests.count == occupancy) { guests }.or "guests number must match the room_type '#{rt}':#{occupancy}, got #{guests.count}: '#{guests.join(', ')}'"
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
    result = prepare params_proto
    result.should be_a Success
    request = result.fetch   # the valid object, ready to use
    request.hotel_code.should == "STO0001"
    request.check_in.should   == Date.new(2012, 06, 15)
    request.nights.should     == 3
    request.room_type.should  == 'DR'
    request.guests.should     == ['Max Payne', 'Jenny Payne']
  end

  def prepare(params)
    properties = HotelBookingRequestParams.methods - Module.methods
    klas = Struct.new(*properties)
    Monadic::Validation.fill(klas, params, HotelBookingRequestParams)
  end

  it 'reports too few guests' do
    result = prepare params_proto.reject {|key| key == 'guest2'}
    result.should be_a Failure
    result.fetch.guests.should == Failure("guests number must match the room_type 'DR':2, got 1: 'Max Payne'")
  end

  it 'reports an invalid room_type' do
    result = prepare params_proto.merge 'room_type' => 'XX'
    result.should be_a Failure
    result.fetch.room_type.should be_a Failure
  end

  it 'reports an invalid check_in time' do
    result = prepare params_proto.merge 'check_in' => '2012-11-31'
    result.should be_a Failure
    request = result.fetch
    request.check_in.should == Failure("check_in invalid date, got '2012-11-31'")
  end

  it 'builds a failure request with no params' do
    result = prepare({})
    result.should be_a Failure
    request = result.fetch
    request.hotel_code.should == Failure("hotel_code must be of pattern XXX0001, got ''")
    request.nights.should     == Failure("nights must be a number greater than 0, got ''")
    request.room_type.should  == Failure("room_type must be one of 'SR, DR, TR, QR', got ''")
    request.check_in.should be_a Failure
    request.check_in.fetch.should =~ /check_in.*, got ''/
    request.guests.should     == Failure("guests number must match the room_type '':99, got 0: ''")
  end

end
