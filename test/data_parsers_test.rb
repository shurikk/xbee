require 'spec_helper'

describe Xbee::DataParsers do
  before do
    @serial = MiniTest::Mock.new
  end

  subject { Xbee::Base.new(@serial) }

  describe "#parse_response" do
    it "returns empty hash when data is nil or empty" do
      subject.parse_response(nil).must_equal({})
      subject.parse_response("").must_equal({})
    end

    it "raises an exception when response is not supported" do
      assert_raises(NoMethodError) {
        subject.parse_response("\x00")
      }
    end

    it "produces response hash" do
      assert_equal subject.parse_response("\x7712345678BBODATA"), {
        :id => :bar, :param1 => "12345678", :param2 => "BB",
        :options => "O", :data=> "DATA"
      }
    end

    it "understands null_terminated fields" do
      assert_equal subject.parse_response("\x55\x00\x0012345\x00DATA"), {
        :id => :foo, :param1 => "\x00\x00", :param2 => "12345", :data => "DATA"
      }
    end

    it "supports post-processing using lambda functions from :parsing" do
      assert_equal subject.parse_response("\x33\x02"), {
        :id => :foo, :param1 => 4
      }
    end
  end

  describe "#parse_samples_header" do
    it "parses 3 bytes header" do
      assert_equal subject.parse_samples_header("\x01\x01\x01"), [1, [0, 8], [], 257, 3]
    end
  end

  describe "#parse_samples" do
    it "parses samples data" do
      assert_equal subject.parse_samples("\x01\x01\x01\x01\x01\x01\x01"), { "dio-0" => true, "dio-8" => true }
    end
  end

end
