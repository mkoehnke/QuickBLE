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

struct Static {
    static let ServiceUUIDKey : String = "ServiceUUIDKey"
    static let CharacteristicUUIDKey : String = "CharacteristicUUIDKey"
}

class Configuration {
    
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
        let title = NSLocalizedString("Arduino Connection", comment: "")
        let text = NSLocalizedString("Please enter the SERVICE and CHARACTERISTIC unique identifiers of your Arduino:", comment: "")
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addTextField { (serviceTextField) in
            serviceTextField.placeholder = NSLocalizedString("Service Identifier", comment: "")
            serviceTextField.text = configuration[Static.ServiceUUIDKey] ?? ""
        }
        alert.addTextField { (characteristicTextField) in
            characteristicTextField.placeholder = NSLocalizedString("Characteristic Identifier", comment: "")
            characteristicTextField.text = configuration[Static.CharacteristicUUIDKey] ?? ""
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .default, handler: { (action) in
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
    
    class func retrieveConfiguration() -> [String : String] {
        var configuration = [String : String]()
        configuration[Static.ServiceUUIDKey] = UserDefaults.standard.string(forKey: Static.ServiceUUIDKey) ?? ""
        configuration[Static.CharacteristicUUIDKey] = UserDefaults.standard.string(forKey: Static.CharacteristicUUIDKey) ?? ""
        return configuration
    }
}

extension Configuration {
    fileprivate class func topViewController() -> UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController
    }
}
