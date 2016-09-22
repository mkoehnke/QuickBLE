//
// ViewController.swift
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
import BLEHelper

class ViewController: UIViewController {

    @IBOutlet weak var connectionLabel : UILabel!
    @IBOutlet weak var button : UIButton!
    
    var bleHelper: BLEHelper?
    
    enum ButtonState : String {
        case on = "On"
        case off = "Off"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !Configuration.hasBeenSetup() {
            Configuration.presentConfiguration { [weak self] (setupComplete) in
                if setupComplete { self?.start() }
            }
        } else {
            start()
        }
    }
    
    func start() {
        let config = Configuration.retrieveConfiguration()
        if let service = config[Static.ServiceUUIDKey], let characteristic = config[Static.CharacteristicUUIDKey] {
            bleHelper = BLEHelper.start(service: service, delegate: self)
            bleHelper?.read(uuid: characteristic) { [weak self] (value) in
                self?.updateButtonState(value: value)
            }
        }
    }
    
    func stop() {
        bleHelper?.stop()
    }
}

extension ViewController {
    @IBAction func buttonTouched(sender: AnyObject) {
        let config = Configuration.retrieveConfiguration()
        if let characteristic = config[Static.CharacteristicUUIDKey] {
            let value : Int8 = (button.title(for: .normal) == ButtonState.on.rawValue) ? 1 : 0
            bleHelper?.write(value: value, for: characteristic)
        }
    }
    func updateButtonState(value: Int8) {
        button.setTitle((value == 0) ? ButtonState.on.rawValue : ButtonState.off.rawValue, for: .normal)
        button.isEnabled = (Configuration.hasBeenSetup()) && bleHelper?.connectedPeripheral != nil
    }
}

extension ViewController : BLEHelperDelegate {
    func helperDidChangeConnectionState(peripheral: String, isConnected: Bool) {
        connectionLabel.text = (isConnected) ? "Connected to \(peripheral)" : "Disconnected"
    }
    func helperDidWrite(value: Int8, uuid: String) {
        updateButtonState(value: value)
    }
}

extension ViewController {
    @IBAction func settingsButtonTouched(sender: AnyObject) {
        Configuration.presentConfiguration { [weak self] (setupComplete) in
            if setupComplete {
                self?.stop()
                self?.start()
            }
        }
    }
}
