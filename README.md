Overview
========

`Rack::MobileDetect` detects mobile devices and adds an
`X_MOBILE_DEVICE` header to the request is a mobile device is
detected.  The strategy for detecting a mobile device is as
follows:

1. Search for a 'targeted' mobile device. A targeted mobile device is
  a device you may want to provide special content to because it has
  advanced capabilities - for example and iPhone or Android phone.
  Targeted mobile devices are detected via a `Regexp` applied against
  the HTTP User-Agent header.

  By default, the targeted devices are iPhone, Android and iPod. If
  a targeted device is detected, the token match from the regular
  expression will be the value passed in the `X_MOBILE_DEVICE` header,
  i.e.: `X_MOBILE_DEVICE: iPhone`

1. Search for a UAProf device. More about UAProf detection can be
  found [here](http://www.developershome.com/wap/detection/detection.asp?page=profileHeader).

  If a UAProf device is detected, it will have `X_MOBILE_DEVICE: true`

1. Look at the HTTP Accept header to see if the device accepts WAP
  content. More information about this form of detection is found
  [here](http://www.developershome.com/wap/detection/detection.asp?page=httpHeaders).

  Any device detected using this method will have `X_MOBILE_DEVICE`
  set to 'true'.

1. Use a 'catch-all' regex. The current catch-all regex was taken from
  the [mobile-fu project](http://github.com/brendanlim/mobile-fu)

  Any device detected using this method will have `X_MOBILE_DEVICE: true`

Notes
=====

If none of the detection methods detected a mobile device, the
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

See the unit test source code for more info.
