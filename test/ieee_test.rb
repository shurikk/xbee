require 'spec_helper'

describe Xbee::IEEE do
  before do
    @serial = MiniTest::Mock.new
  end

  subject { Xbee::IEEE.new(@serial) }

  describe "#method_missing" do
    describe "ATID command" do
      it "builds a command frame and writes to serial port" do
        @serial.expect :write, true, ["\x7E\x00\x04\x08\x01\x49\x44\x69"]
        subject.at(:command => 'ID')
        @serial.verify
      end
    end
  end
end
