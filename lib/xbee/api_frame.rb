module Xbee
  class ApiFrame
    attr_reader :data, :raw_data

    START_BYTE = 0x7E
    ESCAPE_BYTE = 0x7D
    XON_BYTE = 0x11
    XOFF_BYTE = 0x13
    ESCAPE_BYTES = [START_BYTE, ESCAPE_BYTE, XON_BYTE, XOFF_BYTE]

    def initialize(data = "", escaped = false)
      @data = data
      @raw_data = ""
      @escaped = escaped
    end

    def self.escape(data)
      data.bytes.map do |byte|
        (ESCAPE_BYTES.include?(byte) ? [ESCAPE_BYTE, 0x20 ^ byte] : [byte]).pack("C*")
      end.join
    end

    def checksum
      [0xFF - @data.bytes.to_a.inject(&:+) & 0xFF].pack('C')
    end

    def verify(checksum)
      (@data.bytes.to_a.inject(&:+) + checksum) & 0xFF == 0xFF
    end

    def size_in_bytes
      [@data.size].pack('n')
    end

    def output
      data = [size_in_bytes, @data, checksum].join

      if @escaped && @raw_data.size == 0
        @raw_data = Xbee::ApiFrame.escape(data)
      end

      data = @raw_data if @escaped

      [START_BYTE].pack('C') + data
    end

    def remaining_bytes
      remaining = 3
      remaining += @raw_data[1..2].unpack('n')[0] + 1 if @raw_data.size >= 3
      remaining - @raw_data.size
    end

    def fill(byte)
      if @unescape_next_byte
        byte = [byte.unpack('C').first ^ 0x20].pack('C')
        @unescape_next_byte = false
      elsif @escaped && byte.bytes.first == ESCAPE_BYTE
        @unescape_next_byte = true
        return
      end

      @raw_data << byte
    end

    def parse
      raise "frame size is smaller than 3 bytes" if @raw_data.size < 3
      @data = @raw_data[3..-2]
      raise "Invalid checksum" unless verify(@raw_data[-1].unpack('C')[0])
    end
  end
end
