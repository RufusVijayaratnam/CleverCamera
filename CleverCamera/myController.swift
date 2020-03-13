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
    
    var allowTX = true
    var lastPosition: UInt16 = 255
    
    var myView: UIImageView!
    var resetInitilisationButton: UIButton!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        
        let screen = UIScreen.main.bounds
        let width = screen.width
        let height = screen.height
        
        let theFrame = CGRect(x: 0, y: 50,width: width,height: width * 1.7777777)
        let aspectRatio = CGSize(width: 3024, height: 4032)
        myView = UIImageView(frame: AVMakeRect(aspectRatio: aspectRatio, insideRect: theFrame))
        self.view.addSubview(myView)
        
        let buttonFrame = CGRect(x: 48, y: height - 86, width: width - 2 * 48, height: 48)
        resetInitilisationButton = UIButton(frame: buttonFrame)
        resetInitilisationButton.backgroundColor = UIColor.blue
        resetInitilisationButton.setTitle("Reset initialisation", for: .normal)
        resetInitilisationButton.addTarget(self, action: #selector(resetInitialisation), for: .touchUpInside)
        self.view.addSubview(resetInitilisationButton)
        
        self.view.backgroundColor = UIColor.white
        
        self.CleverCamera = OpenCVWrapper(imageView: self.myView)
        self.CleverCamera.startCamera()
        
        print("this will run");
        
        NotificationCenter.default.addObserver(self, selector: #selector(myController.connectionChanged(_:)), name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
        
        
            //this is a random git test
        _ = btDiscoverySharedInstance
        
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
    
    @objc func resetInitialisation() {
        self.CleverCamera.resetInitialisation()
    }

}

