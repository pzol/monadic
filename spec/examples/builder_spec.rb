require 'spec_helper'

class BSONTestConverter
  class InvalidBSONString < StandardError; end
  def self.from_string(s)
    raise InvalidBSONString unless s =~ /^[0-9a-z]{24}$/
    return self.new(s)
  end

  def initialize(s)
    @bson = s
  end

  def to_s
    @bson
  end

  def ==(other)
    return 0 unless other.is_a? BSONTestConverter
    return to_s <=> other.to_s
  end
end

class DatabaseReader
  def self.find(id)
    return { 'request_id' => '197412101130' } if id.to_s == '4fe48bcfcf79520644088180'
  end
end

module Transaction
  def self.fetch(params)
    return Failure('params must be a Hash') unless params.is_a? Hash

    Either(Maybe(params)['id']).or('id is missing').
      >= {|v| Try { BSONTestConverter.from_string(v) }.or("id '#{v}' is not a valid BSON id") }.
      >= {|v| Try { DatabaseReader.find(v)           }.or("'#{v}' not found")                 }
  end

  def self.logs(request_id)
    Success([request_id])
  end
end

describe 'builder' do
  # id = BSON::ObjectId.from_string(params[:id])
    # @tr = MongoMapper.database.collection("log").find_one(id)
    # @rid = @tr['request_id']
    # @logs = LogReader.new.links(@rid)
  it 'builds' do
    Transaction.fetch({}).should == Failure('id is missing')
    Transaction.fetch({'id' => '123'                     }).should == Failure("id '123' is not a valid BSON id")
    Transaction.fetch({'id' => '000000000000000000000000'}).should == Failure("'000000000000000000000000' not found")

    doc = Transaction.fetch({'id' => '4fe48bcfcf79520644088180'})
    doc.should == Success({"request_id"=>"197412101130"})

    doc.bind { Failure('logs not found') }.should == Failure('logs not found')

    logs = doc.
      >= {|v| Transaction.logs(v['request_id']) }

    logs.should == Success(['197412101130'])
  end
end
