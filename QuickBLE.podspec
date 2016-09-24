Pod::Spec.new do |s|

  s.name         = "QuickBLE"
  s.version      = "0.9.0"
  s.summary      = "A simple helper for communicating with Bluetooth LE devices (Arduino 101, etc.)"

  s.description  = <<-DESC
                   A simple helper for communicating with Bluetooth LE devices (Arduino 101, etc.) written in Swift.
		   DESC

  s.homepage     = "https://github.com/mkoehnke/QuickBLE"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author       = "Mathias Köhnke"

  s.ios.deployment_target = '9.1'
  s.osx.deployment_target = '10.11'

  s.source       = { :git => "https://github.com/mkoehnke/QuickBLE.git", :tag => s.version.to_s }

  s.source_files  = "Sources/*.{swift}"
  s.exclude_files = "Sources/Exclude"

  s.requires_arc = true

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }
end
