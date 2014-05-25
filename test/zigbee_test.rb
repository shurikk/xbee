require 'spec_helper'

describe Xbee::ZigBee do
  before do
    @serial = MiniTest::Mock.new
  end

  subject { Xbee::ZigBee.new(@serial) }

  describe ".parse_samples_header" do
    it "parses 4 bytes header" do
      assert_equal subject.parse_samples_header("\x01\x01\x01\x01"), [1, [0], [0], 1, 4]
    end
  end

  describe ".parse_is_at_response" do
    it "parses zigbee ATIS response" do
      info = {
        :id => :at_response,
        :command => "is",
        :status => "\x00",
        :parameter => "~\x00\x12\x92\x00\x13\xA2\x00@\xAC\xC2\xB4U}\x01\x01\x00\x02\x00\x00\x02~"
      }

      subject.parse_is_at_response(info).must_equal(
        {"dio-1"=>true, "dio-4"=>true, "adc-1"=>41472, "adc-4"=>16556, "adc-7"=>49844}
      )
    end
  end

  describe ".parse_nd_at_response" do
    it "parses zigbee ATND response" do
      info = {
        :id => :at_response,
        :command => "ND",
        :status => "\x00",
        :parameter => "aaAAAAAAAAID\x00ppTSPPMM"
      }

      assert_equal subject.parse_nd_at_response(info), {
        :source_addr => "aa",
        :source_addr_long => "AAAAAAAA",
        :node_identifier => "ID",
        :parent_address => "pp",
        :device_type=> "T",
        :status=> "S",
        :profile_id=> "PP",
        :manufacturer=> "MM"
      }
    end
  end

  describe ".method_missing" do
    describe "ATID command" do
      it "builds a command frame and writes to serial port" do
        @serial.expect :write, true, ["\x7E\x00\x04\x08\x01\x49\x44\x69"]
        subject.at(:command => 'ID')
        @serial.verify
      end
    end
  end
end
