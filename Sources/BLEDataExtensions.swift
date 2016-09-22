//
// NSData+Int8.swift
//
// Copyright (c) 2016 Mathias Koehnke (http://www.mathiaskoehnke.de)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// This is an impoved version of SimpleBluetoothIO by Nebojsa Petrovic
// @see https://github.com/nebs/hello-bluetooth


import Foundation

extension Data {

    static func dataWithValue<T:CharacteristicDataConverter>(_ value: T) -> Data {
        var variableValue : T = value
        return Data(bytes: UnsafeMutablePointer(&variableValue), count: MemoryLayout<T>.size)
    }

    func value<T:CharacteristicDataConverter>() -> T? {
        return T.value(self)
    }
}


public protocol CharacteristicDataConverter {
    static func value(_ data: Data?) -> Self?
}

extension String : CharacteristicDataConverter {
    public static func value(_ data: Data?) -> String? {
        if let data = data {
            return String(data: data, encoding: String.Encoding.utf8)
        }
        return nil
    }
}

extension Int8 : CharacteristicDataConverter {
    public static func value(_ data: Data?) -> Int8? {
        if let data = data {
            var value: UInt8 = 0
            data.copyBytes(to: &value, count: MemoryLayout<UInt8>.size)
            return Int8(value)
        }
        return nil
    }
}
