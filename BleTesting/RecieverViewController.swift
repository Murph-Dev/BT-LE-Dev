//
//  RecieverViewController.swift
//  BleTesting
//
//  Created by Michael Murphy on 5/9/19.
//  Copyright © 2019 Michael Murphy. All rights reserved.
//

import UIKit
import CoreBluetooth

class RecieverViewController: UIViewController {
    
    /****** IBOutlets ******/
    //Views
    @IBOutlet weak var OutputView: UIView!
    @IBOutlet weak var SearchView: UIView!
    
    //Labels
    @IBOutlet weak var DeviceStatusLabel: UILabel!
    @IBOutlet weak var LiveOutputLabel: UILabel!
    
    //TextFields
    @IBOutlet weak var DeviceNameTextField: UITextField!
    
    //TextViews
    @IBOutlet weak var OutputLogTextView: UITextView!
    
    /****** Global Vars ******/
    //Managers & Peripherals
    var centralManager: CBCentralManager!
    var activeDevice: CBPeripheral!
    var textCharacteristic: CBCharacteristic!
    var activeDeviceName: String? = nil
    
    //UUIDs
    let RECIEVER_UUID = CBUUID(string: "D78D2B74-0CD9-4477-95F7-962AF9FB471F")
    let SENDER_UUID = CBUUID(string: "9AD98870-5337-4C06-AA75-1CD51655BFD8")
    
    //Services
    let TEXT_CHARACTERISTIC = CBUUID(string:"0x2A3D")
    //let TEXT_CHARACTERISTIC = CBUUID(string: "AA5E74B3-86AE-421F-9B45-CDB6BD098D75")
    

    override func viewDidLoad() {
        super.viewDidLoad()

        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        OutputView.isHidden = true
        SearchView.isHidden = false
    }
    
    /************ Device State Functions ************/
    fileprivate func deviceDiscovered(){
        SearchView.isHidden = true
        OutputView.isHidden = false
        
        clearOutputView()
        
        DeviceStatusLabel.text = "DEVICE DISCOVERED"
        DeviceNameTextField.text = "\(activeDeviceName ?? "NIL")"
        OutputLogTextView.text = OutputLogTextView.text + "\n" + "Discovered Device: \(activeDeviceName ?? "NIL")"
        OutputLogTextView.text = OutputLogTextView.text + "\n" + "Waiting to connect..."
    }
    fileprivate func deviceConnected(){
        DeviceStatusLabel.text = "DEVICE CONNECTED"
        OutputLogTextView.text = OutputLogTextView.text + "\n" + "Device \(activeDeviceName ?? "NIL") connected successfully"
    }
    fileprivate func recievedData(message: String?){
        LiveOutputLabel.text = message ?? "NIL"
        OutputLogTextView.text = OutputLogTextView.text + "\n" + "\(message ?? "NIL")"
    }
    fileprivate func deviceDisconnected(){
        LiveOutputLabel.text = "---"
        DeviceStatusLabel.text = "NO DEVICE"
        DeviceNameTextField.text = nil
        
        OutputLogTextView.text = OutputLogTextView.text + "\n" + "WARNING: Device \(activeDeviceName ?? "NIL") disconnected..."
        
        presentAlertController(title: "Disconnected", message: "The active device has disconnected. Confirm to reconnect.", type: .alertConfirm, actionText: "OK")
        
        activeDevice = nil
        textCharacteristic = nil
    }
    fileprivate func setSearchView(){
        SearchView.isHidden = false
        OutputView.isHidden = true
    }
    
    fileprivate func clearOutputView(){
        OutputLogTextView.text = nil
        DeviceNameTextField.text = nil
        DeviceStatusLabel.text = "NO DEVICE"
        LiveOutputLabel.text = "---"
    }
    

}

extension RecieverViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Central is Powered On")
            centralManager.scanForPeripherals(withServices: [SENDER_UUID])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        //if(peripheral.name == "Mike's iPhone"){
            print("Peripheral: \(peripheral.name) | UUID: \(peripheral.identifier)")
            activeDevice = peripheral
            centralManager.stopScan()
        if let advertisementName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            activeDeviceName = advertisementName
        } else {
            activeDeviceName = activeDevice.name ?? "NIL"
        }
            deviceDiscovered()
            centralManager.connect(peripheral, options: nil)
        //}
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        activeDevice.delegate = self
        activeDevice.discoverServices([SENDER_UUID])
        deviceConnected()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        deviceDisconnected()
    }
    
}

extension RecieverViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        for service in peripheral.services! {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
//        if let service = peripheral.services?.first(where: { $0.uuid == SENDER_UUID }) {
//            //peripheral.discoverCharacteristics([TEXT_CHARACTERISTIC], for: service)
//            peripheral.discoverCharacteristics(nil, for: service)
//        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            print(characteristic.uuid)
            
            let characteristic = characteristic as CBCharacteristic
            if (characteristic.uuid.isEqual(TEXT_CHARACTERISTIC)) {
                print("FOUND CORRECT CHARACTERISTIC")
                textCharacteristic = characteristic
                activeDevice.setNotifyValue(true, for: textCharacteristic)
                //activeDevice.readValue(for: textCharacteristic)
                //if let messageText = messageTextField.text {
                    //let data = messageText.data(using: .utf8)
                   // peripheral.writeValue(data!, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                //}
            }
        }
//        if let characteristic = service.characteristics?.first(where: { $0.uuid == TEXT_CHARACTERISTIC }) {
//            peripheral.setNotifyValue(true, for: characteristic)
//        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            print("Data Found: \(characteristic.value)")
            let message: String? = String(data: data, encoding: String.Encoding.utf8) as String?
            recievedData(message: message)
        } else{
            print("NO DATA FOUND!!!")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error changing notification state: \(error.localizedDescription)")
        } else {
            activeDevice.readValue(for: textCharacteristic)
        }
    }
    
}

extension RecieverViewController {
    enum AlertType {
        case alert
        case alertShy //This alert will not show up if there is an alert already presented
        case alertConfirm
    }
    
    func presentAlertController(title: String, message: String, type: AlertType, actionText: String?) {
        
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if type == .alertConfirm {
            //let OKAction = UIAlertAction(title: actionText ?? "OK", style: UIAlertAction.Style.cancel, handler: nil)
            let OKAction = UIAlertAction(title: actionText ?? "OK", style: UIAlertAction.Style.cancel) { (action) in
                self.clearOutputView()
                self.centralManager.scanForPeripherals(withServices: [self.SENDER_UUID])
                self.setSearchView()
            }
            ac.addAction(OKAction)
        }
        
        // Fix for multiple alerts being present at a time :MM
        if(self.presentedViewController == nil){
            if type == .alertShy {
                present(ac, animated: false)
            } else {
                present(ac, animated: true)
            }
        } else {
            // Do not show this alert
            if type == .alertShy {
                return
            }
            self.presentedViewController?.dismiss(animated: false, completion: {
                self.present(ac, animated: true)
            })
        }
    }
    
}
