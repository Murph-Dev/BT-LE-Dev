//
//  TextSenderViewController.swift
//  BleTesting
//
//  Created by Michael Murphy on 5/9/19.
//  Copyright © 2019 Michael Murphy. All rights reserved.
//

import UIKit
import CoreBluetooth

class TextSenderViewController: UIViewController {
    
    /****** IBOutlets ******/
    //Views
    @IBOutlet weak var OutputView: UIView!
    @IBOutlet weak var SearchView: UIView!
    
    //TextFields
    @IBOutlet weak var CustomMessageTextField: UITextField!
    @IBOutlet weak var DeviceNameTextField: UITextField!
    
    //TextViews
    @IBOutlet weak var OutputLogTextView: UITextView!
    
    /****** Global Vars ******/
    //Managers
    var peripheralManager: CBPeripheralManager!
    var textService: CBMutableService!
    var writeCharacteristics: CBMutableCharacteristic!
    
    let WR_UUID = CBUUID(string: "0x2A3D")
    let WR_PROPERTIES: CBCharacteristicProperties = [.read, .notify]
    let WR_PERMISSIONS: CBAttributePermissions = .readable
    
    //UUIDs
    let RECIEVER_UUID = CBUUID(string: "D78D2B74-0CD9-4477-95F7-962AF9FB471F")
    let SENDER_UUID = CBUUID(string: "9AD98870-5337-4C06-AA75-1CD51655BFD8")
    
    var sentData: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        //Dismiss keybaord on return
        CustomMessageTextField.delegate = self
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    

    /************ Button Press Funcs ************/
    @IBAction func broadcastHello(_ sender: Any) {
        sentData = false
        let helloString = "Hello"
        let helloData = helloString.data(using: .utf8)
        sentData = peripheralManager.updateValue(helloData!, for: writeCharacteristics, onSubscribedCentrals: nil)
        print("Data Sent: \(sentData)")
        OutputLogTextView.text = OutputLogTextView.text + "\n" + "Sent: \(helloString)"
    }
    @IBAction func broadcastGoodbye(_ sender: Any) {
        sentData = false
        let goodbyeString = "Goodbye"
        let goodbyeData = goodbyeString.data(using: .utf8)
        sentData = peripheralManager.updateValue(goodbyeData!, for: writeCharacteristics, onSubscribedCentrals: nil)
        print("Data Sent: \(sentData)")
        OutputLogTextView.text = OutputLogTextView.text + "\n" + "Sent: \(goodbyeString)"
    }
    @IBAction func broadcastWhatsUp(_ sender: Any) {
        sentData = false
        let wuString = "Whats Up?"
        let wuData = wuString.data(using: .utf8)
        sentData = peripheralManager.updateValue(wuData!, for: writeCharacteristics, onSubscribedCentrals: nil)
        print("Data Sent: \(sentData)")
        OutputLogTextView.text = OutputLogTextView.text + "\n" + "Sent: \(wuString)"
    }
    @IBAction func broadcastTesting(_ sender: Any) {
        sentData = false
        let testingString = "Testing"
        let testingData = testingString.data(using: .utf8)
        sentData = peripheralManager.updateValue(testingData!, for: writeCharacteristics, onSubscribedCentrals: nil)
        print("Data Sent: \(sentData)")
        OutputLogTextView.text = OutputLogTextView.text + "\n" + "Sent: \(testingString)"
    }
    @IBAction func broadcastMessage(_ sender: Any) {
        sentData = false
        let messageString = "Message"
        let messageData = messageString.data(using: .utf8)
        sentData = peripheralManager.updateValue(messageData!, for: writeCharacteristics, onSubscribedCentrals: nil)
        print("Data Sent: \(sentData)")
        OutputLogTextView.text = OutputLogTextView.text + "\n" + "Sent: \(messageString)"
    }
    @IBAction func broadcastBlue(_ sender: Any) {
        sentData = false
        let blueString = "Blue"
        let blueData = blueString.data(using: .utf8)
        sentData = peripheralManager.updateValue(blueData!, for: writeCharacteristics, onSubscribedCentrals: nil)
        print("Data Sent: \(sentData)")
        OutputLogTextView.text = OutputLogTextView.text + "\n" + "Sent: \(blueString)"
    }
    @IBAction func broadcastCustomMessage(_ sender: Any) {
        sentData = false
        let customString = CustomMessageTextField.text ?? "NIL"
        let customData = customString.data(using: .utf8)
        sentData = peripheralManager.updateValue(customData!, for: writeCharacteristics, onSubscribedCentrals: nil)
        print("Data Sent: \(sentData)")
        OutputLogTextView.text = OutputLogTextView.text + "\n" + "Sent: \(customString)"
        CustomMessageTextField.text = nil
    }
    
    /************ State Functions ************/
    fileprivate func peripheralPoweredOn(){
        SearchView.isHidden = true
        OutputView.isHidden = false
        
        DeviceNameTextField.text = UIDevice.current.name
        
        OutputLogTextView.text = nil
    }
}

extension TextSenderViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            print("Peripheral is Powered On")
            
            peripheralPoweredOn()
            
            textService = CBMutableService(type: SENDER_UUID, primary: true)
            writeCharacteristics = CBMutableCharacteristic(type: WR_UUID, properties: WR_PROPERTIES, value: nil, permissions: WR_PERMISSIONS)
            
            textService.characteristics = [writeCharacteristics]
            
            peripheralManager.add(textService)
            
            let advertisementData = UIDevice.current.name
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[SENDER_UUID],
                                                CBAdvertisementDataLocalNameKey: advertisementData])
            
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Central subscribed to this peripheral: \(central.identifier)")
    }
    
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if let value = request.value {
                
                //here is the message text that we receive, use it as you wish.
                let messageText = String(data: value, encoding: String.Encoding.utf8) as String?
                
                OutputLogTextView.text = OutputLogTextView.text + "\n" + "Write Recieved: \(messageText ?? "NIL")"
                
                let echoText = "Write Echo: \(messageText ?? "NIL")"
                let echoData = echoText.data(using: .utf8)
                peripheralManager.updateValue(echoData!, for: writeCharacteristics, onSubscribedCentrals: nil)
                
                OutputLogTextView.text = OutputLogTextView.text + "\n" + "Echoing back write..."
            }
            self.peripheralManager.respond(to: request, withResult: .success)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Peripheral Recieved a READ")
    }
    
    
}



extension TextSenderViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
