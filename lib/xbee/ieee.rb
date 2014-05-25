# encoding: ascii
module Xbee
  class IEEE < Xbee::Base
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
        id:               { size: 1,   default: "\x01" },
        frame_id:         { size: 1,   default: "\x00" },
        dest_addr:        { size: 2,   default: nil },
        options:          { size: 1,   default: "\x00" },
        data:             { size: nil, default: nil }
      },

      tx_long_addr: {
        id:               { size: 1,   default: "\x00" },
        frame_id:         { size: 1,   default: "\x00" },
        dest_addr:        { size: 8,   default: nil },
        options:          { size: 1,   default: "\x00" },
        data:             { size: nil, default: nil }
      }
    }

    RESPONSES = {
      "\x80" => {
        name: :rx_long_addr,
        spec: {
          source_addr: { size: 8 },
          rssi: { size: 1 },
          options: { size: 1 },
          rf_data: { size: nil }
        }
      },

      "\x81" => {
        name: :rx,
        spec: {
          source_addr: { size: 2 },
          rssi: { size: 1 },
          options: { size: 1 },
          rf_data:{ size: nil }
        }
      },

      "\x82" => {
        name: :rx_io_data_long_addr,
        spec: {
          source_addr_long: { size: 8 },
          rssi: { size: 1 },
          options: { size: 1 },
          samples: { size: nil }
        },
        parsing: [
          [:samples, lambda {|info| parse_samples(info[:samples]) }]
        ]
      },

      "\x83" => {
        name: :rx_io_data,
        spec: {
          source_addr: { size: 2 },
          rssi: { size: 1 },
          options: { size: 1 },
          samples: { size: nil }
        },
        parsing: [
          [:samples, lambda {|info| parse_samples(info[:samples]) }]
        ]
      },

      "\x89" => {
        name: :tx_status,
        spec: {
          frame_id: { size: 1 },
          status: { size: 1 }
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
          [:parameter, lambda {|info| parse_is_at_response(info) }]
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
      }
    }

    def parse_is_at_response(info)
      if [:at_response, :remote_at_response].include?(info[:id]) && info[:command].upcase == 'IS' && info[:status] == "\x00"
         parse_samples(info[:parameter])
      else
        info[:parameter]
      end
    end
  end
end
