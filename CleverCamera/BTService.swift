//
//  BTService.swift
//  CleverCamera
//
//  Created by Rufus Vijayaratnam on 07/03/2020.
//  Copyright © 2020 Rufus Vijayaratnam. All rights reserved.
//

import Foundation
import CoreBluetooth

/* Services & Characteristics UUIDs */
let BLEServiceUUID = CBUUID(string: "0xFFE0")
let PositionCharUUID = CBUUID(string: "FFE1")
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

class BTService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var positionCharacteristic: CBCharacteristic?
    
    var shouldSend: Bool = true
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()
        
        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }
    
    deinit {
        self.reset()
    }
    
    func startDiscoveringServices() {
        self.peripheral?.discoverServices([BLEServiceUUID])
    }
    
    func reset() {
        if peripheral != nil {
            peripheral = nil
        }
        
        // Deallocating therefore send notification
        self.sendBTServiceNotificationWithIsBluetoothConnected(false)
    }
    
    // Mark: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let uuidsForBTService: [CBUUID] = [PositionCharUUID]
        
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        guard let services = peripheral.services else { return }
              for service in services {
                print("the services are here: \(service)")
                
        peripheral.discoverCharacteristics(nil, for: service)      }
        
        if (error != nil) {
            return
        }
        
        if ((peripheral.services == nil) || (peripheral.services!.count == 0)) {
            // No Services
            return
        }
        
        for service in peripheral.services! {
            print("services are \(service)")
            if service.uuid == BLEServiceUUID {
                peripheral.discoverCharacteristics(uuidsForBTService, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == PositionCharUUID {
                    self.positionCharacteristic = (characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("a characteristic \(characteristic)")
                    // Send notification that Bluetooth is connected and all required characteristics are discovered
                    self.sendBTServiceNotificationWithIsBluetoothConnected(true)
                }
            }
        }
    }
    
    // Mark: - Private
    //var myNumber: UInt8 = 1
    func writePosition(_ position: [UInt16]) {
        // See if characteristic has been discovered before writing to it
      /*  if !shouldSend {
            print("skipping")
            return
        }*/
        
        if let positionCharacteristic = self.positionCharacteristic {
            print("running send")
            
            let byteX0: UInt8 = UInt8(position[0] >> 8)
            let byteX1: UInt8 = UInt8(position[0]  & 0x00ff)
            
            let byteY0: UInt8 = UInt8(position[1] >> 8)
            let byteY1: UInt8 = UInt8(position[1] & 0x00ff)
            
            let data: [UInt8] = [byteX0, byteX1, byteY0, byteY1]
            
            let writeData = Data(data)
            print("the data is \(writeData)")
           // myNumber  = myNumber + 1
            self.peripheral?.writeValue(writeData, for: positionCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
            shouldSend = false
        }
    }
    
    func sendBTServiceNotificationWithIsBluetoothConnected(_ isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]
        NotificationCenter.default.post(name: Notification.Name(rawValue: BLEServiceChangedStatusNotification), object: self, userInfo: connectionDetails)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case positionCharacteristic?.uuid:
            print("received value is: \(String(describing: characteristic.value))")
            shouldSend = true
        default:
            print("unknown received characteristic UUID: \(String(describing: characteristic.uuid))")
            shouldSend = true
        }
    }
    
}
