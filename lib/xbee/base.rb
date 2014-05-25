module Xbee
  class Base
    include Xbee::DataParsers

    def initialize(serial, options = {})
      @serial = serial
      @options = {
        :escaped => false
      }.merge(options)
    end

    def method_missing(name, *args, &block)
      if self.class::COMMANDS[name]
        _ = write(build_command(name, args[0]))
        args[0][:read] ? wait_read_frame : _
      else
        super
      end
    end

    def build_command(cmd, params = {})
      spec = self.class::COMMANDS[cmd]
      raise "command #{cmd} is not supported" unless spec

      packet = ""
      params = params || {}

      spec.each do |field, settings|
        data = params[field]

        if settings[:size]
          if !data
            if settings[:default]
              data = settings[:default]
            else
              raise "expected parameter: #{field}, size: #{settings[:size]} byte(s) is missing"
            end
          end

          if data.size != settings[:size]
            raise "parameter #{field} is not #{settings[:size]} byte(s) long"
          end
        end

        packet << data if data
      end

      packet
    end

    def write(data)
      @serial.write(Xbee::ApiFrame.new(data, @options[:escaped]).output)
    end

    def wait_for_frame
      while true do
        frame = Xbee::ApiFrame.new("", @options[:escaped])
        byte = @serial.read(1)

        if byte.bytes.first == Xbee::ApiFrame::START_BYTE
          frame.fill(byte)

          while frame.remaining_bytes > 0 do
            frame.fill(@serial.read(1))
          end

          begin
            frame.parse
            # empty frame, will restart, why?
            return frame if frame.data.size > 0
          rescue
            # bad frame, will restart
          end
        else
          # empty unparsed frame, happens on timeout
          return frame
        end
      end
    end

    def wait_read_frame(read_timeout = 0)
      @serial.read_timeout = read_timeout
      parse_response(wait_for_frame.data)
    end
  end
end
