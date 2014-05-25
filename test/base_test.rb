require 'spec_helper'

module Xbee
  class Base
    COMMANDS = {
      :cmd => {
        :id => { :size => 1, :default => "\x08" },
        :command => { :size => 2 },
        :parameter => {}
      },
    }

    RESPONSES = {
      "\x77" => {
        :name => :bar,
        :spec => {
          :param1 => { :size => 8 },
          :param2 => { :size => 2 },
          :options => { :size => 1 },
          :data => { }
        }
      },
      "\x55" => {
        :name => :foo,
        :spec => {
          :param1 => { :size => 2},
          :param2 => { :size => :null_terminated },
          :data => {}
        }
      },
      "\x33" => {
        :name => :foo,
        :spec => {
          :param1 => { :size => 1 },
        },
        :parsing => [
          [:param1, lambda {|info| info[:param1].bytes.first * 2 }],
        ]
      },
    }
  end
end

describe Xbee::Base do
  before do
    @serial = MiniTest::Mock.new
  end

  subject { Xbee::Base.new(@serial) }

  describe ".build_command" do
    it "raises an exception when command is not implemented" do
      assert_raises(RuntimeError) {
        subject.build_command(:xyz)
      }
    end

    it "uses command default value" do
      subject.build_command(:cmd, :command => 'XX').must_equal "\x08XX"
    end

    it "builds command and validates parameters" do
      assert_raises(RuntimeError) {
        subject.build_command(:cmd)
      }

      assert_raises(RuntimeError) {
        subject.build_command(:cmd, :command => "xyz")
      }
    end

    it "builds command with optional fields" do
      subject.build_command(:cmd, :command => 'zz', :parameter => 'xxx').must_equal "\x08zzxxx"
      subject.build_command(:cmd, :command => 'zz').must_equal "\x08zz"
    end
  end

  describe ".write" do
    it "writes data (API frame output) to a serial port" do
      data = "\x00"
      @serial.expect :write, true, [Xbee::ApiFrame.new(data).output]
      subject.write(data)
      @serial.verify
    end
  end

  describe ".wait_for_frame" do
    it "reads serial port until valid frame arrives" do
    end
  end
end
