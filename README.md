XBee Library
============

port of https://pypi.python.org/pypi/XBee

Installation
------------

    $ gem install xbee


Documentation
-------------

* [Ruby Docs](http://rubydoc.info/gems/xbee)
* [IEEE commands and responses](http://rubydoc.info/gems/xbee/Xbee/ZigBee.html)
* [ZigBee commands and response](http://rubydoc.info/gems/xbee/Xbee/IEEE.html)
* [List of AT commands](http://examples.digi.com/wp-content/uploads/2012/07/XBee_ZB_ZigBee_AT_Commands.pdf)


Tools & Resources
-----------------

X-CTU alternatives

* [XBee communication libraries and utilities](https://github.com/roysjosh/xbee-comm)
* [Moltosenso Iron 1.0](http://www.moltosenso.com/#/pc==/client/fe/download.php)


Example
-------

```ruby
require 'xbee'
require 'serialport'

serial = SerialPort.new "/dev/tty.usbserial-A95L5ZJN", 9600
client = Xbee::ZigBee.new(serial, :escaped => true)

Thread.new do
  while true do
    frame = client.wait_read_frame
    p frame
  end
end

%w(id my ni dd ch op pl).each do |cmd|
  client.at(:command => cmd)
  sleep 1
end
```

Contributors
------------

* [Alexander Kabanov](http://github.com/shurikk)
