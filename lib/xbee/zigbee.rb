# encoding: ascii
module Xbee
  class ZigBee < Xbee::Base
    COMMANDS = {
      at: {
        id:               { size: 1,   default: "\x08" },
        frame_id:         { size: 1,   default: "\x01" },
        command:          { size: 2,   default: nil },
        parameter:        { size: nil, default: nil }
      },

      queued_at: {
        id:               { size: 1,   default: "\x09" },
        frame_id:         { size: 1,   default: "\x01" },
        command:          { size: 2,   default: nil },
        parameter:        { size: nil, default: nil }
      },

      remote_at: {
        id:               { size: 1,   default: "\x17" },
        frame_id:         { size: 1,   default: "\x00" },
        dest_addr_long:   { size: 8,   default: [0].pack('Q') },
        dest_addr:        { size: 2,   default: "\xFF\xFE" },
        options:          { size: 1,   default: "\x02" },
        command:          { size: 2,   default: nil },
        parameter:        { size: nil, default: nil }
      },

      tx: {
        id:               { size: 1,   default: "\x10" },
        frame_id:         { size: 1,   default: "\x01" },
        dest_addr_long:   { size: 8,   default: nil },
        dest_addr:        { size: 2,   default: nil },
        broadcast_radius: { size: 1,   default: "\x00" },
        options:          { size: 1,   default: "\x00" },
        data:             { size: nil, default: nil }
      },

      tx_explicit: {
        id:               { size: 1,   default: "\x11" },
        frame_id:         { size: 1,   default: "\x00" },
        dest_addr_long:   { size: 8,   default: nil },
        dest_addr:        { size: 2,   default: nil },
        src_endpoint:     { size: 1,   default: nil },
        dest_endpoint:    { size: 1,   default: nil },
        cluster:          { size: 2,   default: nil },
        profile:          { size: 2,   default: nil },
        broadcast_radius: { size: 1,   default: "\x00" },
        options:          { size: 1,   default: "\x00" },
        data:             { size: nil, default: nil }
      }
    }

    RESPONSES = {
      "\x90" => {
        name: :rx,
        spec: {
          source_addr_long: { size: 8 },
          source_addr: { size: 2 },
          options: { size: 1 },
          rf_data: { size: nil }
        }
      },

      "\x91" => {
        name: :rx_explicit,
        spec: {
          source_addr_long: { size: 8 },
          source_addr: { size: 2 },
          source_endpoint: { size: 1 },
          dest_endpoint: { size: 1 },
          cluster: { size: 2 },
          profile: { size: 2 },
          options: { size: 1 },
          rf_data: { size: nil }
        }
      },

      "\x92" => {
        name: :rx_io_data_long_addr,
        spec: {
          source_addr_long: { size: 8 },
          source_addr: { size: 2 },
          options: { size: 1 },
          samples: { size: nil }
        },
        parsing: [
          [:samples, lambda {|info| parse_samples(info[:samples]) }]
        ]
      },

      "\x8b" => {
        name: :tx_status,
        spec: {
          frame_id: { size: 1 },
          dest_addr: { size: 2 },
          retries: { size: 1 },
          deliver_status: { size: 1 },
          discover_status: { size: 1 }
        }
      },

      "\x8a" => {
        name: :status,
        spec: {
          status: { size: 1 }
        }
      },

      "\x88" => {
        name: :at_response,
        spec: {
          frame_id: { size: 1 },
          command: { size: 2 },
          status: { size: 1 },
          parameter: { size: nil }
        },
        parsing: [
          [:parameter, lambda {|info| parse_is_at_response(info) }],
          [:parameter, lambda {|info| parse_nd_at_response(info) }]
        ]
      },

      "\x97" => {
        name: :remote_at_response,
        spec: {
          frame_id: { size: 1 },
          source_addr_long: { size: 8 },
          source_addr: { size: 2 },
          command: { size: 2 },
          status: { size: 1 },
          parameter: { size: nil }
        },
        parsing: [
          [:parameter, lambda {|info| parse_is_at_response(info) }]
        ]
      },

      "\x95" => {
        name: :node_id_indicator,
        spec: {
          sender_addr_long: { size: 8 },
          sender_addr: { size: 2 },
          options: { size: 1 },
          source_addr: { size: 2 },
          source_addr_long: { size: 8 },
          node_id: { size: :null_terminated },
          parent_source_addr: { size: 2 },
          device_type: { size: 1 },
          source_event: { size: 1 },
          digi_profile_id: { size: 2 },
          manufacturer_id: { size: 2 }
        }
      }
    }

    def parse_samples_header(io_bytes)
      header_size = 4
      io_bytes = io_bytes.bytes.to_a
      sample_count = io_bytes[0]

      dio_mask = (io_bytes[1] << 8 | io_bytes[2]) & 0x0E7F
      aio_mask = io_bytes[3]

      dio_channels = (0..13).inject([]) do |memo,i|
        memo << i if dio_mask & (1 << i) > 0
        memo
      end.sort

      aio_channels = (0..8).inject([]) do |memo,i|
        memo << i if aio_mask & (1 << i) > 0
        memo
      end.sort

      [sample_count, dio_channels, aio_channels, dio_mask, header_size]
    end

    def parse_is_at_response(info)
      if [:at_response, :remote_at_response].include?(info[:id]) && info[:command].upcase == "IS" && info[:status] == "\x00"
        parse_samples(info[:parameter])
      else
        info[:parameter]
      end
    end

    def parse_nd_at_response(info)
      if :at_response == info[:id] && info[:command].upcase == "ND" && info[:status] == "\x00"
        nt_index = 10 + info[:parameter][10..-1].index("\x00")

        result = {
          :source_addr => info[:parameter][0..1],
          :source_addr_long => info[:parameter][2..9],
          :node_identifier => info[:parameter][10..nt_index - 1],
          :parent_address => info[:parameter][nt_index + 1..nt_index + 2],
          :device_type => info[:parameter][nt_index + 3],
          :status => info[:parameter][nt_index + 4],
          :profile_id => info[:parameter][nt_index + 5..nt_index + 6],
          :manufacturer => info[:parameter][nt_index + 7..nt_index + 8]
        }

        if nt_index + 9 != info[:parameter].size
          raise "invalid ND response length, expected: #{info[:parameter].size}, got: #{nt_index + 9} byte(s)"
        end

        result
      else
        info[:parameter]
      end
    end
  end
end
