Gem::Specification.new do |s|
  s.name = 'xbee'
  s.version = '0.1.0'
  s.date = '2014-05-21'

  s.summary = "XBee Library"
  s.description = "XBee Library (port of https://pypi.python.org/pypi/XBee)"

  s.authors = ["Alexander Kabanov"]
  s.email = "shurikk@gmail.com"
  s.homepage = "https://github.com/shurikk/xbee"
  s.licenses = ["MIT"]

  s.require_paths = %w[lib]

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.md LICENSE]

  s.add_runtime_dependency 'serialport'

  # = MANIFEST =
 s.files = %w[
 Gemfile
 LICENSE
 README.md
 Rakefile
 lib/xbee.rb
 lib/xbee/api_frame.rb
 lib/xbee/base.rb
 lib/xbee/data_parsers.rb
 lib/xbee/ieee.rb
 lib/xbee/version.rb
 lib/xbee/zigbee.rb
 test/api_frame_test.rb
 test/base_test.rb
 test/data_parsers_test.rb
 test/ieee_test.rb
 test/spec_helper.rb
 test/zigbee_test.rb
 xbee.gemspec
 ]
 # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
