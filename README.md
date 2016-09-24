# QuickBLE

[![Twitter: @mkoehnke](https://img.shields.io/badge/contact-@mkoehnke-blue.svg?style=flat)](https://twitter.com/mkoehnke)
[![Version](https://img.shields.io/cocoapods/v/QuickBLE.svg?style=flat)](http://cocoadocs.org/docsets/QuickBLE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-orange.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![License](https://img.shields.io/cocoapods/l/QuickBLE?style=flat)](http://cocoadocs.org/docsets/QuickBLE)
[![Platform](https://img.shields.io/cocoapods/p/QuickBLE.svg?style=flat)](http://cocoadocs.org/docsets/QuickBLE)


A simple wrapper for CoreBluetooth to easily connect to Bluetooth LE devices and read/write it's values. It is **not intended as a fully-featured library**. You can **consider it as a simple prototyping tool** to get a connection to your device up and running quickly.


Take a look at the iOS demo in the `Example` directory to see how to use it. It shows how to turn on/off the LED of an **[Arduino 101](https://www.arduino.cc/en/Main/ArduinoBoard101)**. 

<img src="Resources/example.png" width=375 style="border:1px solid #CCCCCC"/>


# Usage

QuickBLE has **only a four methods** to connect and manipulate the values of a connected peripheral:

## Initialization

This static function returns an initialized QuickBLE object and starts the service discovery / connection:

```swift
class func start(service: String, delegate: QuickBLEDelegate?) -> QuickBLE
```

#### Example

```swift
helper = QuickBLE.start(service: "arduino", delegate: self)
```

## Reading a value

This function reads the value of the specified characteristic and calls the passed closure with the result:

```swift
func read<T:CharacteristicValue>(uuid: String, result: @escaping (_ value: T?) -> Void)
```

#### Example

```swift
helper.read(uuid: "led") { (value : Int8?) in
    // evaluate value
}
```

## Writing a value

The following sets a value for the specified characteristic unique identifier:

```swift
func write<T:CharacteristicValue>(value: T, for uuid: String)
```

#### Example

```swift
helper.write(value: Int8(1), for: "led")
```


## Stop

Cancels the connection to the peripheral.

```swift
func stop()
```

#### Example

```swift
helper.stop()
```

# Supported Types

QuickBLE currently supports the following types for characteristic values:

* `String`
* `Int8`

This list can be easily expanded with additional types by implementing the following protocol:

```swift
public protocol CharacteristicValue {
    static func getValue(fromData data: Data?) -> Self?
}
```


# Attributions
* Based on [Hello Bluetooth](https://github.com/nebs/hello-bluetooth) by [Nebojsa Petrovic](https://github.com/nebs)

# License
QuickBLE is available under the MIT license. See the LICENSE file for more info.


# Recent Changes
The release notes can be found [here](https://github.com/mkoehnke/QuickBLE/releases).
