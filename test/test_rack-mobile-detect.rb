require 'helper'

class TestRackMobileDetect < Test::Unit::TestCase

  context "An app with mobile-device defaults" do
    setup do
      @app = test_app
      @rack = Rack::MobileDetect.new(@app)
    end

    should "not detect a non-mobile device" do
      env = test_env
      @rack.call(env)
      assert !env.key?(x_mobile)
    end

    should "detect all default targeted devices" do
      env = test_env({ 'HTTP_USER_AGENT' => ipod })
      @rack.call(env)
      assert_equal 'iPod', env[x_mobile]

      env = test_env({ 'HTTP_USER_AGENT' => iphone })
      @rack.call(env)
      assert_equal 'iPhone', env[x_mobile]

      env = test_env({ 'HTTP_USER_AGENT' => android })
      @rack.call(env)
      assert_equal 'Android', env[x_mobile]

      env = test_env({ 'HTTP_USER_AGENT' => ipad })
      @rack.call(env)
      assert_equal 'iPad', env[x_mobile]
    end

    should "detect UAProf device" do
      env = test_env({ 'HTTP_X_WAP_PROFILE' =>
                       '"http://www.blackberry.net/go/mobile/profiles/uaprof/9000_80211g/4.6.0.rdf"' })
      @rack.call(env)
      assert_equal "true", env[x_mobile]

      env = test_env({ 'HTTP_PROFILE' =>
                       'http://www.blackberry.net/go/mobile/profiles/uaprof/9000_80211g/4.6.0.rdf' })
      @rack.call(env)
      assert_equal "true", env[x_mobile]

      # See http://www.developershome.com/wap/detection/detection.asp?page=uaprof
      env = test_env({ 'HTTP_80_PROFILE' =>
                       'http://wap.sonyericsson.com/UAprof/T68R502.xml' })
      @rack.call(env)
      assert_equal "true", env[x_mobile]
    end

    should "not detect spurious profile header match" do
      env = test_env({ 'HTTP_X_PROFILE_FOO' => 'bar' })
      @rack.call(env)
      assert !env.key?(x_mobile)
    end

    should "detect wap in Accept header" do
      env = test_env({ 'HTTP_ACCEPT' => 'text/html,application/xhtml+xml,application/vnd.wap.xhtml+xml,*/*;q=0.5' })
      @rack.call(env)
      assert_equal "true", env[x_mobile]

      env = test_env({ 'HTTP_ACCEPT' => 'application/vnd.wap.wmlscriptc;q=0.7,text/vnd.wap.wml;q=0.7,*/*;q=0.5' })
      @rack.call(env)
      assert_equal "true", env[x_mobile]
    end

    should "detect additional devices in catchall" do
      env = test_env({ 'HTTP_USER_AGENT' => blackberry })
      @rack.call(env)
      assert_equal "true", env[x_mobile]

      env = test_env({ 'HTTP_USER_AGENT' => samsung })
      @rack.call(env)
      assert_equal "true", env[x_mobile]

      env = test_env({ 'HTTP_USER_AGENT' => webos })
      @rack.call(env)
      assert_equal "true", env[x_mobile]

      env = test_env({ 'HTTP_USER_AGENT' => 'opera' })
      @rack.call(env)
      assert !env.key?(x_mobile)
    end
  end

  context "An app with a custom targeted option" do
    setup do
      @app = test_app
      # Target Samsung SCH and Blackberries. Note case-sensitivity.
      @rack = Rack::MobileDetect.new(@app, :targeted => /SCH-\w*$|[Bb]lack[Bb]erry\w*/)
    end

    should "capture the targeted token" do
      env = test_env({ 'HTTP_USER_AGENT' => samsung })
      @rack.call(env)
      assert_equal 'SCH-U960', env[x_mobile]

      env = test_env({ 'HTTP_USER_AGENT' => "Samsung SCH-I760" })
      @rack.call(env)
      assert_equal 'SCH-I760', env[x_mobile]

      env = test_env({ 'HTTP_USER_AGENT' => blackberry })
      @rack.call(env)
      assert_equal 'BlackBerry9000', env[x_mobile]

      # An iPhone will be detected, but the token won't be captured
      env = test_env({ 'HTTP_USER_AGENT' => iphone })
      @rack.call(env)
      assert_equal "true", env[x_mobile]
    end
  end

  context "An app with a custom catchall option" do
    setup do
      @app = test_app
      # Custom catchall regex
      @rack = Rack::MobileDetect.new(@app, :catchall => /mysupermobiledevice/i)
    end

    should "catch only the specified devices" do
      env = test_env({ 'HTTP_USER_AGENT' => "MySuperMobileDevice v1.0" })
      @rack.call(env)
      assert_equal "true", env[x_mobile]

      env = test_env({ 'HTTP_USER_AGENT' => samsung })
      @rack.call(env)
      assert !env.key?(x_mobile)
    end
  end

  context "An app with a custom redirect" do
    setup do
      @app = test_app
      # Custom redirect
      @rack = Rack::MobileDetect.new(@app,
                                     :redirect_to => 'http://m.example.com/')
    end

    should "redirect to mobile website" do
      env = test_env({ 'HTTP_USER_AGENT' => iphone })
      status, headers, body = @rack.call(env)
      assert_equal 'iPhone', env[x_mobile]

      assert_equal(301, status)
      assert_equal({'Location' => "http://m.example.com/"}, headers)
    end
  end

  context "An app with a custom redirect map" do
    setup do
      @app = test_app
      redirects = {
        "myphone" => "http://m.example.com/myphone",
        "yourphone" => "http://m.example.com/yourphone"
      }
      # Target fake devices
      @rack = Rack::MobileDetect.new(@app,
                                     :targeted => /myphone|yourphone/,
                                     :redirect_map => redirects)
    end

    should "redirect to the custom url of the targeted devices" do
      env = test_env({ 'HTTP_USER_AGENT' => 'myphone rocks' })
      status, headers, body = @rack.call(env)
      assert_equal 'myphone', env[x_mobile]

      assert_equal(301, status)
      assert_equal({'Location' => "http://m.example.com/myphone"}, headers)


      env = test_env({ 'HTTP_USER_AGENT' => 'yourphone sucks' })
      status, headers, body = @rack.call(env)
      assert_equal 'yourphone', env[x_mobile]

      assert_equal(301, status)
      assert_equal({'Location' => "http://m.example.com/yourphone"}, headers)

    end

    should "not redirect a non-targeted device" do
      env = test_env({ 'HTTP_USER_AGENT' => 'some wap phone' })
      status, headers, body = @rack.call(env)
      assert_equal 'true', env[x_mobile]

      assert_not_equal(301, status)
    end
  end

  context "An app with a custom redirect map and redirect_to option" do
    setup do
      @app = test_app
      redirects = {
        "myphone" => "http://m.example.com/myphone",
        "yourphone" => "http://m.example.com/yourphone"
      }
      # Target fake devices
      @rack = Rack::MobileDetect.new(@app,
                                     :targeted => /myphone|yourphone/,
                                     :redirect_map => redirects,
                                     :redirect_to => 'http://m.example.com/genericdevice')
    end

    should "use the redirect value in the redirect map when targeted" do
      env = test_env({ 'HTTP_USER_AGENT' => 'myphone rocks' })
      status, headers, body = @rack.call(env)
      assert_equal 'myphone', env[x_mobile]

      assert_equal(301, status)
      assert_equal({'Location' => "http://m.example.com/myphone"}, headers)

    end

    should "use redirect_to to redirect a device not in the map" do
      env = test_env({ 'HTTP_USER_AGENT' => 'some wap phone' })
      status, headers, body = @rack.call(env)
      assert_equal 'true', env[x_mobile]

      assert_equal(301, status)
      assert_equal({'Location' => "http://m.example.com/genericdevice"}, headers)
    end

  end


  # Expected x_header
  def x_mobile
    Rack::MobileDetect::X_HEADER
  end

  # User agents for testing
  def ipad
    'Mozilla/5.0 (iPad; U; CPU OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B334b Safari/531.21.10'
  end
  def ipod
    'Mozilla/5.0 (iPod; U; CPU iPhone OS 2_2 like Mac OS X; en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5G77 Safari/525.20'
  end

  def iphone
    'Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_1 like Mac OS X; en-us) AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7C144 Safari/528.16'
  end

  def android
    'Mozilla/5.0 (Linux; U; Android 2.0; ld-us; sdk Build/ECLAIR) AppleWebKit/530.17 (KHTML, like Gecko) Version/4.0 Mobile Safari/530.17'
  end

  def blackberry
    'BlackBerry9000/4.6.0.167 Profile/MIDP-2.0 Configuration/CLDC-1.1 VendorID/102'
  end

  def samsung
    'Mozilla/4.0 (compatible; MSIE 6.0; BREW 3.1.5; en )/800x480 Samsung SCH-U960'
  end

  def webos
    'Mozilla/5.0 (webOS/1.4.0; U; en-US) AppleWebKit/532.2 (KHTML, like Gecko) Version/1.0 Safari/532.2 Pre/1.1'
  end

  # Our test web app. Doesn't do anything.
  def test_app()
    Class.new { def call(app); true; end }.new
  end

  # Test environment variables
  def test_env(overwrite = {})
    {
      'GATEWAY_INTERFACE'=> 'CGI/1.2',
      'HTTP_ACCEPT'=> 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'HTTP_ACCEPT_CHARSET'=> 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
      'HTTP_ACCEPT_ENCODING'=> 'gzip,deflate',
      'HTTP_ACCEPT_LANGUAGE'=> 'en-us,en;q=0.5',
      'HTTP_CONNECTION'=> 'keep-alive',
      'HTTP_HOST'=> 'localhost:4567',
      'HTTP_KEEP_ALIVE'=> 300,
      'HTTP_USER_AGENT'=> 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.1.3) Gecko/20090920 Firefox/3.5.3 (Swiftfox)',
      'HTTP_VERSION'=> 'HTTP/1.1',
      'PATH_INFO'=> '/',
      'QUERY_STRING'=> '',
      'REMOTE_ADDR'=> '127.0.0.1',
      'REQUEST_METHOD'=> 'GET',
      'REQUEST_PATH'=> '/',
      'REQUEST_URI'=> '/',
      'SCRIPT_NAME'=> '',
      'SERVER_NAME'=> 'localhost',
      'SERVER_PORT'=> '4567',
      'SERVER_PROTOCOL'=> 'HTTP/1.1',
      'SERVER_SOFTWARE'=> 'Mongrel 1.1.5',
      'rack.multiprocess'=> false,
      'rack.multithread'=> true,
      'rack.request.form_hash'=> '',
      'rack.request.form_vars'=> '',
      'rack.request.query_hash'=> '',
      'rack.request.query_string'=> '',
      'rack.run_once'=> false,
      'rack.url_scheme'=> 'http',
      'rack.version'=> '1: 0'
    }.merge(overwrite)
  end
end
