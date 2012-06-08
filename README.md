Install
=======

    sudo gem install rack-mobile-detect

In your code:

    require 'rack/mobile-detect'

Overview
========

`Rack::MobileDetect` is Rack middleware for ruby webapps that detects
mobile devices. It adds an `X_MOBILE_DEVICE` header to the request if
a device is detected. The strategy for detecting a mobile device is as
follows:

### Targeted Detection ###

Search for a 'targeted' mobile device. A targeted mobile device is a
device you may want to provide special content to because it has
advanced capabilities - for example and iPhone or Android phone.
Targeted mobile devices are detected via a `Regexp` applied against
the HTTP User-Agent header.

By default, the targeted devices are iPhone, iPad, Android and
iPod. If a targeted device is detected, the token match from the
regular expression will be the value passed in the `X_MOBILE_DEVICE`
header, i.e.: `X_MOBILE_DEVICE: iPhone`


### UAProf Detection ###

Search for a UAProf device. More about UAProf detection can be found
[here](http://www.developershome.com/wap/detection/detection.asp?page=profileHeader).

If a UAProf device is detected, it will have `X_MOBILE_DEVICE: true`

### Accept Header Detection ###

Look at the HTTP Accept header to see if the device accepts WAP
content. More information about this form of detection is found
[here](http://www.developershome.com/wap/detection/detection.asp?page=httpHeaders).

Any device detected using this method will have `X_MOBILE_DEVICE: true`

### Catchall Detection ###

Use a 'catch-all' regex. The current catch-all regex was taken from
the [mobile-fu project](http://github.com/brendanlim/mobile-fu)

Any device detected using this method will have `X_MOBILE_DEVICE: true`

Notes
=====

If none of the detection methods detect a mobile device, the
`X_MOBILE_DEVICE` header will be _absent_.

Note that `Rack::MobileDetect::X_HEADER` holds the string
'X\_MOBILE\_DEVICE' that is inserted into the request headers.

Usage
=====

    use Rack::MobileDetect

This allows you to do mobile device detection with the defaults.

    use Rack::MobileDetect, :targeted => /SCH-\w*$|[Bb]lack[Bb]erry\w*/

In this usage you can set the value of the regular expression used to
target particular devices. This regular expression captures Blackberry
and Samsung SCH-* model phones. For example, if a phone with the
user-agent: 'BlackBerry9000/4.6.0.167 Profile/MIDP-2.0
Configuration/CLDC-1.1 VendorID/102' connects, the value of
`X_MOBILE_DEVICE` will be set to 'BlackBerry9000'

    use Rack::MobileDetect, :catchall => /mydevice/i

This allows you to limit the catchall expression to only the device
list you choose.

Redirects
=========

    use Rack::MobileDetect, :redirect_to => 'http://m.example.com/'

This allows you to choose a custom redirect path any time a mobile
device is detected.

    use Rack::MobileDetect, :targeted => /BlackBerry|iPhone/,
                            :redirect_map => { 'BlackBerry' => 'http://m.example.com/blackberry',
                                               'iPhone' => 'http://m.example.com/iphone' }

This allows you to map specific redirect URLs to targeted devices. The
key in the redirect_map should be the value of the matched pattern.

    use Rack::MobileDetect, :targeted => /BlackBerry|iPhone/,
                            :redirect_map => { 'BlackBerry' => 'http://m.example.com/blackberry',
                                               'iPhone' => 'http://m.example.com/iphone' },
                            :redirect_to => 'http://m.example.com/'

This allows you to map targeted devices to specific URLs. Non-targeted
mobile devices will redirect to the url specified by redirect_to.

In the example above, BlackBerrys and iPhones get redirected to
device-specific URLs. All other mobile devices get redirected to
'http://m.example.com'.


Utils
=====

A Sinatra app called echo_env.rb is available in the
[util/](http://github.com/talison/rack-mobile-detect/tree/master/util/)
directory. Hit this app with a mobile device to see the various HTTP
headers and whether or not the `X_MOBILE_DEVICE` header is added by
`Rack::MobileDetect`.

See the [unit test source code](http://github.com/talison/rack-mobile-detect/tree/master/test/) for more info.
