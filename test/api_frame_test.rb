# encoding: ascii

require 'spec_helper'

describe Xbee::ApiFrame do
  describe "frame generation" do
    subject { Xbee::ApiFrame.new("\x00") }

    describe ".output" do
      it "creates a frame using single byte" do
        subject.output.must_equal "\x7E\x00\x01\x00\xFF"
      end
    end
  end

  describe "frame parsing" do
    subject { Xbee::ApiFrame.new }

    describe ".remaining_bytes" do
      it "calculates number of expected/remaining bytes" do
        bytes = "\x7E\x00\x04\x00\x00\x00\x00\xFF"
        [2,1,5,4].each_with_index do |number, index|
          subject.fill(bytes[index])
          subject.remaining_bytes.must_equal number
        end
      end
    end

    describe ".parse" do
      it "produces single byte data" do
        "\x7E\x00\x01\x00\xFF".scan(/./).map {|byte| subject.fill(byte) }
        subject.parse
        subject.data.must_equal "\x00"
      end

      it "raises exception when checksum is invalid" do
        "\x7E\x00\x01\x00\xF6".scan(/./).map {|byte| subject.fill(byte) }
        assert_raises(RuntimeError) {
          subject.parse
        }
      end
    end
  end

  describe "escaping" do
    describe "#escape" do
      it "escapes data according to specs" do
        data = [Xbee::ApiFrame::START_BYTE].pack('C')
        expected = [Xbee::ApiFrame::ESCAPE_BYTE, 0x5e].pack('C*')
        Xbee::ApiFrame.escape(data).must_equal expected
      end
    end

    describe ".fill when escaped = true" do
      subject { Xbee::ApiFrame.new("", true) }

      it "unescapes data" do
        "\x7D\x23".scan(/./).map {|byte| subject.fill(byte) }
        subject.raw_data.must_equal "\x03"
      end
    end
  end
end


