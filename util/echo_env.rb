require 'rubygems'
require 'sinatra'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rack/mobile-detect'

use Rack::MobileDetect

# Very simple sinatra app that allows debugging of the headers with
# Rack::MobileDetect. Also useful for looking at various mobile phone
# headers.
get '/' do
  content_type 'text/plain'
  env_string = env.sort.map{ |v| v.join(': ') }.join("\n") + "\n"
  # Print to log if debug is passed, i.e.:
  # http://localhost:4567/?debug
  puts env_string if params.key?('debug')
  env_string
end
