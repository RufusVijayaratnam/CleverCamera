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
        let aspectRatio = CGSize(width: 2160, height: 3840)
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
           
        }
    }

    @objc func matrixOperation(_ pixelu: UInt16, pixelv: UInt16) {
        let pixelU = Float(pixelu)
        let pixelV = Float(pixelv)
        let rotationX = makeRotationMatrix(angle: degToRadians(30), type: 0)
        let rotationY = makeRotationMatrix(angle: degToRadians(0), type: 1)
        let rotationZ = makeRotationMatrix(angle: degToRadians(24.5), type: 2)
        
        let rotationMatrix: simd_float4x4 = rotationX * rotationZ
        
        var rows: [simd_float4]!
        
        var tx, ty, tz: Float
        tx = 0
        ty = 1990
        tz = 508
        
        rows = [
            simd_float4(1, 0, 0, tx),
            simd_float4(0, 1, 0, ty),
            simd_float4(0, 0, 1, tz),
            simd_float4(0, 0, 0, 1)
        ]
        
        let translationMatrix = float4x4(rows: rows)
        
        let intrinsicCameraRows = [
            simd_float4(1.2355943168554138e+03, 0, 7.4613134664012841e+02, 0),
            simd_float4(0,1.2348377141935975e+03, 5.6902027250972412e+02, 0),
            simd_float4(0, 0, 1, 0),
            simd_float4(0, 0, 0, 1)
        ]
        
        let intrinsicCameraMatrix = float4x4(rows: intrinsicCameraRows)
        
        let transformationMatrix = translationMatrix * rotationMatrix
        
        let pixelVector  = simd_float4(pixelU, pixelV, 1, 1)
        
        let solutionVector = simd_mul((intrinsicCameraMatrix * transformationMatrix).inverse, pixelVector)
        
      //  let position: [UInt16] = [UInt16(solutionVector[0]), UInt16(solutionVector[1])]
        print("3D mapped with x: \(solutionVector[0]) and y: \(solutionVector[1])")
        
        
    }

    func degToRadians(_ angle: Float) -> Float {
        return (angle * .pi) / 180
    }


    func makeRotationMatrix(angle: Float, type: Int) -> simd_float4x4 { // 0 for about x, 1 for y, 2 for z
           var rows: [simd_float4]!
           switch type {
           case 0:
               rows = [
                   simd_float4(1,              0,                  0, 0),
                   simd_float4(0, cos(angle), -sin(angle), 0),
                   simd_float4(0, sin(angle), cos(angle), 0),
                   simd_float4(0,              0,                0, 1)
               ]
           case 1:
               rows = [
                   simd_float4( cos(angle), 0, sin(angle), 0),
                   simd_float4(                0, 1,               0, 0),
                   simd_float4( -sin(angle), 0, cos(angle), 0),
                   simd_float4(0,              0,                0, 1)
               ]
               
           case 2:
               rows = [
                   simd_float4( cos(angle), -sin(angle), 0, 0),
                   simd_float4(sin(angle), cos(angle), 0, 0),
                   simd_float4( 0,          0,          1, 0),
                   simd_float4(0,              0,                0, 1)
               ]
           default:
               print("Dude its gotta be 0, 1, or 2. Okay? Fucking idiot.")
               print("Now we have to return identity matrix, and no one wants that")
               return matrix_identity_float4x4
           }
           
           return float4x4(rows: rows)
           
       }
    
    @objc func resetInitialisation() {
        self.CleverCamera.resetInitialisation()
        let image = imageFromLayer(layer: myView.layer)
        let heightInPoints = image.size.height
        let heightInPixels = heightInPoints * image.scale

        let widthInPoints = image.size.width
        let widthInPixels = widthInPoints * image.scale
        
        print("height: \(heightInPixels) and width: \(widthInPixels)")
    }

    func imageFromLayer(layer:CALayer) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, layer.isOpaque, 0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return outputImage!
    }
    
   
}

