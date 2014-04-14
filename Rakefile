# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/osx'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'Jmpr'
  app.frameworks += ['QuartzCore']
  app.libs = ['/usr/local/lib/libswresample.a', '/usr/local/lib/libswscale.a', '/usr/local/lib/libavcodec.a',
    '/usr/local/lib/libavformat.a', '/usr/local/lib/libavutil.a',
    '/usr/lib/libbz2.dylib', '/usr/lib/libz.dylib', '/usr/lib/libiconv.dylib']
  app.vendor_project 'vendor/ffmpeg', :static, :cflags => '-I/usr/local/include -fobjc-arc'
  app.vendor_project 'vendor/util', :static, :cflags => '-I/usr/local/include -fobjc-arc'
end
