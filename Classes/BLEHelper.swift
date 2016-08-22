// Modified Version of https://github.com/nebs/hello-bluetooth (SimpleBluetoothIO)

// - added read function
// - commands are added to a queue
// - added characteristic propertie to write function

import CoreBluetooth

protocol BLEHelperDelegate: class {
    func helper(_ BLEHelper: BLEHelper, didReceiveValue value: Int8)
}

class BLEHelper: NSObject {
    let serviceUUID: String
    weak var delegate: BLEHelperDelegate?

    internal var centralManager: CBCentralManager!
    internal var connectedPeripheral: CBPeripheral?
    internal var targetService: CBService?
    
    internal var writableCharacteristics = [CBCharacteristic]()
    internal var readRequests = [String : (Int8) -> Void]()
    
    internal let operationQueue = { () -> OperationQueue in 
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
        return queue
    }()
    
    init(serviceUUID: String, delegate: BLEHelperDelegate?) {
        self.serviceUUID = serviceUUID
        self.delegate = delegate

        super.init()

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

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
    
    func close() {
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

extension BLEHelper: CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        connectedPeripheral = peripheral

        if let connectedPeripheral = connectedPeripheral {
            connectedPeripheral.delegate = self
            centralManager.connect(connectedPeripheral, options: nil)
        }
        centralManager.stopScan()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        startScan()
    }
    
    func startScan() {
        operationQueue.isSuspended = true
        centralManager.scanForPeripherals(withServices: [CBUUID(string: serviceUUID)], options: nil)
    }
}

extension BLEHelper: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }

        targetService = services.first
        if let service = services.first {
            targetService = service
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

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

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value, let delegate = delegate else {
            return
        }

        let uuid = characteristic.uuid.uuidString
        if let request = readRequests[uuid] {
            request(data.int8Value())
            readRequests.removeValue(forKey: uuid)
        } else {
            delegate.helper(self, didReceiveValue: data.int8Value())
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing value for peripheral \(peripheral.name): \(error.localizedDescription)")
            return
        }
        peripheral.readValue(for: characteristic) // force 'didUpdateValue' call
    }
}
