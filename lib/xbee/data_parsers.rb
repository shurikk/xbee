# encoding: ascii
module Xbee
  module DataParsers
    def parse_response(data)
      return {} if !data || data.empty?

      packet_id = data[0]
      packet = self.class::RESPONSES[packet_id]

      spec = packet[:spec]

      info = { :id => packet[:name] }
      index = 1

      spec.each do |field, settings|
        if settings[:size] == :null_terminated
          null_terminated_index = index + data[index..-1].index("\x00")
          info[field] = data[index..(null_terminated_index - 1)]
          index = null_terminated_index + 1
        elsif settings[:size]
          raise "response packet was shorter than expected" if index + settings[:size] > data.size
          info[field] = data[index..(index + settings[:size]) - 1]
          index += settings[:size]
        else
          if data[index..-1].size > 0
            info[field] = data[index..-1]
            index += data[index..-1].size
          end

          break
        end
      end

      raise "response packet was longer than #{index} byte(s), got: #{data.size} byte(s)" if index < data.size

      Array(packet[:parsing]).each do |parser|
        info[parser[0]] = instance_exec(info, &(parser[1]))
      end

      info
    end

    def parse_samples_header(io_bytes)
      header_size = 3
      io_bytes = io_bytes.bytes.to_a
      sample_count = io_bytes[0]

      dio_mask = (io_bytes[1] << 8 | io_bytes[2]) & 0x01FF
      aio_mask = (io_bytes[1] & 0xFE) >> 1

      dio_channels = (0..9).inject([]) do |memo, i|
        memo << i if dio_mask & (1 << i) > 0
        memo
      end.sort

      aio_channels = (0..7).inject([]) do |memo, i|
        memo << i if aio_mask & (1 << i) > 0
        memo
      end.sort

      [sample_count, dio_channels, aio_channels, dio_mask, header_size]
    end

    def parse_samples(io_bytes)
      sample_count, dio_channels, aio_channels, dio_mask, header_size =
        parse_samples_header(io_bytes)

      sample_bytes = io_bytes[header_size..-1].bytes.to_a

      samples = {}

      if !dio_channels.empty?
        digital_data_set = (sample_bytes.shift.to_i << 8 | sample_bytes.shift.to_i)
        digital_values = dio_mask & digital_data_set
        dio_channels.each {|i| samples["dio-#{i}"] = ((digital_values >> i) & 1) > 0 }
      end

      aio_channels.each do |i|
        samples["adc-#{i}"] = (sample_bytes.shift.to_i << 8 | sample_bytes.shift.to_i)
      end

      samples
    end
  end
end
