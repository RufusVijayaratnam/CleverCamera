//
//  ViewController.swift
//  CleverCamera
//
//  Created by Rufus Vijayaratnam on 28/02/2020.
//  Copyright © 2020 Rufus Vijayaratnam. All rights reserved.
//

import UIKit
import AVFoundation
import CoreBluetooth



public class myController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    var CleverCamera: OpenCVWrapper!
    var centralManager: CBCentralManager!
    var BTPeripheral: CBPeripheral!
    var peripheral: CBPeripheral?
    var myCharacteristic: CBCharacteristic?
    var theData: UInt8!
    var blueToothSendCount: UInt16 = 0
    
    var timerTXDelay: Timer?
    var allowTX = true
    var lastPosition: UInt16 = 255
    
    var myView: UIImageView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        
        let screen = UIScreen.main.bounds
        let width = screen.width
        
        let theFrame = CGRect(x: 0, y: 50,width: width,height: width * 1.7777777)
        let aspectRatio = CGSize(width: 3024, height: 4032)
        myView = UIImageView(frame: AVMakeRect(aspectRatio: aspectRatio, insideRect: theFrame))
        self.view.addSubview(myView)
        
        self.CleverCamera = OpenCVWrapper(imageView: self.myView)
        self.CleverCamera.startCamera()
        
        print("this will run");
        
        NotificationCenter.default.addObserver(self, selector: #selector(myController.connectionChanged(_:)), name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
        
        
            //this is a random git test
        _ = btDiscoverySharedInstance
        
    }
    
    func changeColour() {
        self.view.backgroundColor = UIColor.red
    }
    
    @objc func connectionChanged(_ notification: Notification) {
        let userInfo = (notification as NSNotification).userInfo as! [String: Bool]
        
        DispatchQueue.main.async(execute: {
            // Set image based on connection status
            if let isConnected: Bool = userInfo["isConnected"] {
                if isConnected {
                    print("We have a connnection")
                } else {
                    print("Not fucking connected yet")
                }
            }
        });
        
    }
    
    @objc func sendData(_ positionX: UInt16, positionY: UInt16 ) {
        self.sendPosition([positionX, positionY])
    }
    
    func sendPosition(_ position: [UInt16]) {
        // Valid position range: 0 to 180
        if !allowTX {
            return
        }
        
        blueToothSendCount += 1
        // Send position to BLE Shield (if service exists and is connected)
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writePosition(position)
           // lastPosition = position;
            
        }
    }
    
    func makeRotationMatrix(angle: Float, type: Int) -> simd_float3x3 { // 0 for about x, 1 for y, 2 for z
        var rows: [simd_float3]!
        switch type {
        case 0:
            rows = [
                simd_float3(1,              0,                  0),
                simd_float3(0, cos(angle), -sin(angle)),
                simd_float3(0, sin(angle), cos(angle))
            ]
        case 1:
            rows = [
                simd_float3( cos(angle), 0, sin(angle)),
                simd_float3(                0, 1,               0),
                simd_float3( -sin(angle), 0, cos(angle))
            ]
            
        case 2:
        rows = [
            simd_float3( cos(angle), -sin(angle), 0),
            simd_float3(sin(angle), cos(angle), 0),
            simd_float3( 0,          0,          1)
        ]
        default:
            print("Dude its gotta be 0, 1, or 2. Okay? Fucking idiot.")
            print("Now we have to return identity matrix, and no one wants that")
            return matrix_identity_float3x3
        }
        
        return float3x3(rows: rows)
        
    }
    
}

