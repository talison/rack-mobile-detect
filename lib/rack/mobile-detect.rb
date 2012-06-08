# The MIT License
#
# Copyright (c) 2009 Tom Alison
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'rack'

module Rack
  #
  # Full project at http://github.com/talison/rack-mobile-detect
  #
  # Rack::MobileDetect detects mobile devices and adds an
  # X_MOBILE_DEVICE header to the request if a mobile device is
  # detected.  The strategy for detecting a mobile device is as
  # follows:
  #
  # 1. Search for a 'targeted' mobile device. A targeted mobile device
  # is a mobile device you may want to provide special content to
  # because it has advanced capabilities - for example an iPad, iPhone or
  # Android device. Targeted mobile devices are detected via a Regexp
  # applied against the HTTP User-Agent header.
  #
  # By default, the targeted devices are iPhone, Android, iPad and iPod. If
  # a targeted device is detected, the token match from the regular
  # expression will be the value passed in the X_MOBILE_DEVICE header,
  # i.e.: X_MOBILE_DEVICE: iPhone
  #
  # 2. Search for a UAProf device. More about UAProf detection can be
  # found here:
  # http://www.developershome.com/wap/detection/detection.asp?page=profileHeader
  #
  # If a UAProf device is detected, the value of X_MOBILE_DEVICE is
  # simply set to 'true'.
  #
  # 3. Look at the HTTP Accept header to see if the device accepts WAP
  # content. More information about this form of detection is found
  # here:
  # http://www.developershome.com/wap/detection/detection.asp?page=httpHeaders
  #
  # Any device detected using this method will have X_MOBILE_DEVICE
  # set to 'true'.
  #
  # 4. Use a 'catch-all' regex. The current catch-all regex was taken
  # from the mobile-fu project. See:
  # http://github.com/brendanlim/mobile-fu
  #
  # Any device detected using this method will have X_MOBILE_DEVICE
  # set to 'true'.
  #
  # If none of the detection methods detected a mobile device, the
  # X_MOBILE_DEVICE header will be absent.
  #
  # Note that Rack::MobileDetect::X_HEADER holds the string
  # 'X_MOBILE_DEVICE' that is inserted into the request headers.
  #
  # Usage:
  # use Rack::MobileDetect
  #
  # This allows you to do mobile device detection with the defaults.
  #
  # use Rack::MobileDetect, :targeted => /SCH-\w*$|[Bb]lack[Bb]erry\w*/
  #
  # In this usage you can set the value of the regular expression used
  # to target particular devices. This regular expression captures
  # Blackberry and Samsung SCH-* model phones. For example, if a phone
  # with the user-agent: 'BlackBerry9000/4.6.0.167 Profile/MIDP-2.0 Configuration/CLDC-1.1 VendorID/102'
  # connects, the value of X_MOBILE_DEVICE will be set to 'BlackBerry9000'
  #
  # use Rack::MobileDetect, :catchall => /mydevice/i
  #
  # This allows you to limit the catchall expression to only the
  # device list you choose.
  #
  # See the unit test source code for more info.
  #
  # Author: Tom Alison (tom.alison at gmail.com)
  # License: MIT
  #
  class MobileDetect
    X_HEADER = 'X_MOBILE_DEVICE'

    # Users can pass in a :targeted option, which should be a Regexp
    # specifying which user-agent agent tokens should be specifically
    # captured and passed along in the X_MOBILE_DEVICE variable.
    #
    # The :catchall option allows specifying a Regexp to catch mobile
    # devices that fall through the other tests.
    def initialize(app, options = {})
      @app = app

      # @ua_targeted holds a list of user-agent tokens that are
      # captured. Captured tokens are passed through in the
      # environment variable. These are special mobile devices that
      # may have special rendering capabilities for you to target.
      @regex_ua_targeted = options[:targeted] || /iphone|android|ipod|ipad/i

      # Match mobile content in Accept header:
      # http://www.developershome.com/wap/detection/detection.asp?page=httpHeaders
      @regex_accept = /vnd\.wap/i

      # From mobile-fu: http://github.com/brendanlim/mobile-fu
      @regex_ua_catchall = options[:catchall] ||
        Regexp.new('palm|blackberry|nokia|phone|midp|mobi|symbian|chtml|ericsson|minimo|' +
                   'audiovox|motorola|samsung|telit|upg1|windows ce|ucweb|astel|plucker|' +
                   'x320|x240|j2me|sgh|portable|sprint|docomo|kddi|softbank|android|mmp|' +
                   'pdxgw|netfront|xiino|vodafone|portalmmm|sagem|mot-|sie-|ipod|up\\.b|' +
                   'webos|amoi|novarra|cdm|alcatel|pocket|ipad|iphone|mobileexplorer|' +
                   'mobile', true)

      # A URL that specifies a single redirect-url for any device
      @redirect_to = options[:redirect_to]
      # A mapping of devices to redirect URLs, for targeted devices
      @redirect_map = options[:redirect_map]
    end

    # Because the web app may be multithreaded, this method must
    # create new Regexp instances to ensure thread safety.
    def call(env)
      device = nil
      user_agent = env.fetch('HTTP_USER_AGENT', '')

      # First check for targeted devices and store the device token
      device = Regexp.new(@regex_ua_targeted).match(user_agent)

      # Fall-back on UAProf detection
      # http://www.developershome.com/wap/detection/detection.asp?page=profileHeader
      device ||= env.keys.detect { |k| k.match(/^HTTP(.*)_PROFILE$/) } != nil

      # Fall back to Accept header detection
      device ||= Regexp.new(@regex_accept).match(env.fetch('HTTP_ACCEPT','')) != nil

      # Fall back on catch-all User-Agent regex
      device ||= Regexp.new(@regex_ua_catchall).match(user_agent) != nil

      if device
        device = device.to_s

        env[X_HEADER] = device
        redirect = check_for_redirect(device)

        if redirect
          path = Rack::Utils.unescape(env['PATH_INFO'])
          return [301, {'Location' => redirect}, []] if redirect && path !~ /^#{redirect}/
        end
      end

      @app.call(env)
    end

    # Checks to see if any redirect options were passed in
    # and returns the appropriate redirect or nil (if no redirect requested)
    def check_for_redirect(device)
      # Find the device-specific redirect in the map, if exists
      return @redirect_map[device] if @redirect_map && @redirect_map.has_key?(device)
      # Return global redirect, or nil
      return @redirect_to
    end
  end
end
