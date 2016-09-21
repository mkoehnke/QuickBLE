//
// Configuration.swift
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

import UIKit

class Configuration {
    
    struct Static {
        fileprivate static let ServiceUUIDKey : String = "ServiceUUIDKey"
        fileprivate static let CharacteristicUUIDKey : String = "CharacteristicUUIDKey"
    }
    
    class func hasBeenSetup() -> Bool {
        if let _ = readValue(key: Static.ServiceUUIDKey), let _ = readValue(key: Static.CharacteristicUUIDKey) {
            return true
        }
        return false
    }
    
    class func readValue(key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }
    
    class func presentConfiguration(dismissBlock: @escaping (_ setupComplete: Bool) -> Void) {
        let configuration = retrieveConfiguration()
        let alert = UIAlertController(title: "Configuration", message: "Enter", preferredStyle: .alert)
        alert.addTextField { (serviceTextField) in
            serviceTextField.placeholder = "Service"
            serviceTextField.text = configuration[Static.ServiceUUIDKey] ?? ""
        }
        alert.addTextField { (characteristicTextField) in
            characteristicTextField.placeholder = "Characteristic"
            characteristicTextField.text = configuration[Static.CharacteristicUUIDKey] ?? ""
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action) in
            let service = alert.textFields?.first?.text
            let characteristic = alert.textFields?.last?.text
            saveConfiguration(service: service, characteristic: characteristic)
            dismissBlock(service != nil && characteristic != nil)
        }))
        topViewController()?.present(alert, animated: true, completion: nil)
    }

    class func saveConfiguration(service: String?, characteristic: String?) {
        UserDefaults.standard.set(service, forKey: Static.ServiceUUIDKey)
        UserDefaults.standard.set(characteristic, forKey: Static.CharacteristicUUIDKey)
        UserDefaults.standard.synchronize()
    }
    
    class func retrieveConfiguration() -> [String : String?] {
        var configuration = [String : String?]()
        configuration[Static.ServiceUUIDKey] = UserDefaults.standard.string(forKey: Static.ServiceUUIDKey)
        configuration[Static.CharacteristicUUIDKey] = UserDefaults.standard.string(forKey: Static.CharacteristicUUIDKey)
        return configuration
    }
}

extension Configuration {
    fileprivate class func topViewController() -> UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController
    }
}
