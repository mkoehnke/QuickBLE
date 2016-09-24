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


/*!
 *  @protocol BLEHelperDelegate
 *
 *  @discussion The delegate of a {@link BLEHelper} object must adopt the <code>BLEHelperDelegate</code> protocol. The
 *              required methods indicate e.g. changes of the connection state and the result of an write operation.
 *
 */
public protocol BLEHelperDelegate: class {
    func helperDidChangeConnectionState(peripheral: String, isConnected: Bool)
    func helperDidUpdate<T:CharacteristicData>(data: T?, uuid: String)
}

/*!
 *  @class BLEHelper
 *
 *  @discussion Entry point to connect to a peripheral.
 *
 */
public class BLEHelper: NSObject {
    
    
    /// Returns the name of the connected peripheral (nil if not connected).
    public var connectedPeripheral : String? {
        return coordinator.connectedPeripheral?.name
    }
    
    /// Returns the delegate object that will receive helper events.
    public weak var delegate : BLEHelperDelegate? {
        return coordinator.delegate
    }
    
    /// Returns the service unique identifier.
    public var service : String {
        return coordinator.service
    }
    
    /// Returns an initialized BLEHelper object and starts the service discovery / connection.
    public class func start(service: String, delegate: BLEHelperDelegate?) -> BLEHelper {
        return BLEHelper(service: service, delegate: delegate)
    }
    
    /// Sets value for the specified characteristic unique identifier.
    public func write<T:CharacteristicValue>(value: T, for uuid: String) {
        coordinator.write(value: value, for: uuid)
    }
    
    /// Reads the value of the specified characteristic.
    public func read<T:CharacteristicValue>(uuid: String, result: @escaping (_ value: T?) -> Void) {
        coordinator.read(uuid: uuid, result: result)
    }
    
    /// Cancels the connection to the peripheral.
    public func stop() {
        coordinator.stop()
    }
    
    
    /// Private Initializers
    
    private var coordinator : BLECoordinator!
    private override init() {}
    private init(service: String, delegate: BLEHelperDelegate?) {
        self.coordinator = BLECoordinator(serviceUUID: service, delegate: delegate)
        super.init()
    }
}


// Hide Protocol Conformance

fileprivate class BLECoordinator : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    weak var delegate: BLEHelperDelegate?
    
    var service: String = "de.mathiaskoehnke.BLEHelper"
    
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var targetService: CBService?
    
    var writableCharacteristics = [CBCharacteristic]()
    var readRequests = [String : (Data?) -> Void]()
    
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
    
    func write<T:CharacteristicValue>(value: T, for uuid: String) {
        operationQueue.addOperation { [weak self] in
            guard let peripheral = self?.connectedPeripheral, let characteristic = self?.writableCharacteristics.filter({ $0.uuid == CBUUID(string: uuid) }).first else {
                BLELogger.log("Could not write value. Peripheral not connected or no characteristic found.")
                return
            }
            if let data = Data.getData(withValue: value) {
                peripheral.writeValue(data, for: characteristic, type: .withResponse)
            }
        }
    }
    
    func read<T:CharacteristicValue>(uuid: String, result: @escaping (_ value: T?) -> Void) {
        operationQueue.addOperation { [weak self] in
            guard let peripheral = self?.connectedPeripheral, let characteristic = self?.writableCharacteristics.filter({ $0.uuid == CBUUID(string: uuid) }).first else {
                BLELogger.log("Could not read value. Peripheral not connected or no characteristic found.")
                return
            }
            
            let convertDataClosure = { (data : Data?) in
                result(T.getValue(fromData: data))
            }
            
            self?.readRequests[uuid] = convertDataClosure
            peripheral.readValue(for: characteristic)
        }
    }
    
    func stop() {
        BLELogger.log("Shutting down ...")
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
        BLELogger.log("Did connect to peripheral '\(peripheral.displayName)' ...")
        delegate?.helperDidChangeConnectionState(peripheral: peripheral.displayName, isConnected: true)
        peripheral.discoverServices(nil)
    }
    
    @objc(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        BLELogger.log("Did discover peripheral '\(peripheral.displayName)' ...")
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
        BLELogger.log("Peripheral '\(peripheral.displayName)' did disconnect ...")
        delegate?.helperDidChangeConnectionState(peripheral: peripheral.displayName, isConnected: false)
        startScan()
    }
    
    func startScan() {
        BLELogger.log("Start scanning for peripherals ...")
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
            BLELogger.log("Did discover service '\(service.uuid.uuidString)' for peripheral '\(peripheral.displayName)' ...")
            targetService = service
            peripheral.discoverCharacteristics(nil, for: service)
            BLELogger.log("Start discovering characteristics for service '\(service.uuid.uuidString)' ...")
        }
    }
    
    @objc(peripheral:didDiscoverCharacteristicsForService:error:)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                BLELogger.log("Did discover characteristic '\(characteristic.uuid.uuidString) for service '\(service.uuid.uuidString)' ...")
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
            request(data)
            readRequests.removeValue(forKey: uuid)
        } else {
            delegate.helperDidUpdate(data: data, uuid: uuid)
        }
    }
    
    @objc(peripheral:didWriteValueForCharacteristic:error:)
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            BLELogger.log("Error writing value for peripheral \(peripheral.name): \(error.localizedDescription)")
            return
        }
        peripheral.readValue(for: characteristic) // forcing 'didUpdateValue' call
    }
}

// MARK : Helper

fileprivate extension CBPeripheral {
    var displayName : String {
        return name ?? "<Unknown>"
    }
}
