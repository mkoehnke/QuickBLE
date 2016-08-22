// Modified Version of https://github.com/nebs/hello-bluetooth (SimpleBluetoothIO)

import Foundation

extension Data {

    static func dataWithValue<T>(_ value: T) -> Data {
        var variableValue : T = value
        return Data(bytes: UnsafeMutablePointer(&variableValue), count: MemoryLayout<T>.size)
    }

    func int8Value() -> Int8 {
        var value: UInt8 = 0
        copyBytes(to: &value, count: MemoryLayout<UInt8>.size)
        return Int8(value)
    }

}
