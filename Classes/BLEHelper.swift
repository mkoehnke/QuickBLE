//
// BLEHelper.swift
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


import CoreBluetooth

public protocol BLEHelperDelegate: class {
    func helperDidChangeConnectionState(peripheral: String, isConnected: Bool)
    func helperDidReceiveValue(value: Int8)
}

public class BLEHelper: NSObject {
    
    public var connectedPeripheral : String? {
        return coordinator.connectedPeripheral?.name
    }
    
    public weak var delegate : BLEHelperDelegate? {
        return coordinator.delegate
    }
    
    public var service : String {
        return coordinator.service
    }
    
    private var coordinator : BLECoordinator!
    
    private override init() {}
    
    private init(service: String, delegate: BLEHelperDelegate?) {
        self.coordinator = BLECoordinator(serviceUUID: service, delegate: delegate)
        super.init()
    }
    
    public class func start(service: String, delegate: BLEHelperDelegate?) -> BLEHelper {
        return BLEHelper(service: service, delegate: delegate)
    }
    
    public func write(value: Int8, for uuid: String) {
        coordinator.write(value: value, for: uuid)
    }
    
    public func read(uuid: String, result: ((_ value: Int8) -> Void)?) {
        coordinator.read(uuid: uuid, result: result)
    }
    
    public func stop() {
        coordinator.stop()
    }
    
}


// Hide Protocol Conformance

fileprivate class BLECoordinator : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    weak var delegate: BLEHelperDelegate?
    
    var service: String = "de.mathiaskoehnke.BLEHelper"
    let defaultPeripheralName : String = "Unknown"
    
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var targetService: CBService?
    
    var writableCharacteristics = [CBCharacteristic]()
    var readRequests = [String : (Int8) -> Void]()
    
    let operationQueue = { () -> OperationQueue in
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
        return queue
    }()
    
    init(serviceUUID: String, delegate: BLEHelperDelegate?) {
        self.service = serviceUUID
        self.delegate = delegate
        
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    private override init() {}
    
    func write(value: Int8, for uuid: String) {
        operationQueue.addOperation { [weak self] in
            guard let peripheral = self?.connectedPeripheral, let characteristic = self?.writableCharacteristics.filter({ $0.uuid == CBUUID(string: uuid) }).first else {
                return
            }
            let data = Data.dataWithValue(value)
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
    
    func read(uuid: String, result: ((_ value: Int8) -> Void)?) {
        operationQueue.addOperation { [weak self] in
            guard let peripheral = self?.connectedPeripheral, let characteristic = self?.writableCharacteristics.filter({ $0.uuid == CBUUID(string: uuid) }).first else {
                return
            }
            self?.readRequests[uuid] = result
            peripheral.readValue(for: characteristic)
        }
    }
    
    func stop() {
        operationQueue.cancelAllOperations()
        centralManager.stopScan()
        if let connectedPeripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(connectedPeripheral)
        }
        connectedPeripheral = nil
        readRequests.removeAll()
        
        // TODO unsubscibe notifications
    }

}

// MARK: CBCentralManagerDelegate

fileprivate extension BLECoordinator {
    @objc(centralManager:didConnectPeripheral:)
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        delegate?.helperDidChangeConnectionState(peripheral: peripheral.name ?? defaultPeripheralName, isConnected: true)
        peripheral.discoverServices(nil)
    }
    
    @objc(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        connectedPeripheral = peripheral
        
        if let connectedPeripheral = connectedPeripheral {
            connectedPeripheral.delegate = self
            centralManager.connect(connectedPeripheral, options: nil)
        }
        centralManager.stopScan()
    }
    
    @objc func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScan()
        }
    }
    
    @objc func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        delegate?.helperDidChangeConnectionState(peripheral: peripheral.name ?? defaultPeripheralName, isConnected: false)
        startScan()
    }
    
    func startScan() {
        operationQueue.isSuspended = true
        centralManager.scanForPeripherals(withServices: [CBUUID(string: service)], options: nil)
    }
}

// MARK: CBPeripheralDelegate

fileprivate extension BLECoordinator {
    @objc func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        
        targetService = services.first
        if let service = services.first {
            targetService = service
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    @objc(peripheral:didDiscoverCharacteristicsForService:error:)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                writableCharacteristics.append(characteristic)
            }
            peripheral.setNotifyValue(true, for: characteristic)
        }
        
        operationQueue.isSuspended = false
    }
    
    @objc(peripheral:didUpdateValueForCharacteristic:error:)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value, let delegate = delegate else {
            return
        }
        
        let uuid = characteristic.uuid.uuidString
        if let request = readRequests[uuid] {
            request(data.int8Value())
            readRequests.removeValue(forKey: uuid)
        } else {
            delegate.helperDidReceiveValue(value: data.int8Value())
        }
    }
    
    @objc(peripheral:didWriteValueForCharacteristic:error:)
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing value for peripheral \(peripheral.name): \(error.localizedDescription)")
            return
        }
        peripheral.readValue(for: characteristic) // force 'didUpdateValue' call
    }
}
