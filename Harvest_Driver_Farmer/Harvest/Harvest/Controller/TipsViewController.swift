//
//  TipsViewController.swift
//  Harvest

import Foundation
import UIKit

class TipsViewController : UIViewController {
    
    @IBOutlet weak var tenPriceLabel: UILabel!
    @IBOutlet weak var fifteenPriceLabel: UILabel!
    @IBOutlet weak var twentyPriceLabel: RoundButton!
    
    @IBOutlet weak var doneButton: RoundButton!
    
    @IBOutlet weak var DriverImage: UIImageView!
    
    @IBOutlet weak var tipReminderLabel: UILabel!
    @IBOutlet weak var tenPercentLabel: RoundButton!
    @IBOutlet weak var fifteenPercentLabel: RoundButton!
    @IBOutlet weak var twentyPercentLabel: RoundButton!
    @IBOutlet weak var backButton: UIButton!
    
    @IBAction func backButtonDidTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func twentyButtonDidTapped(_ sender: Any) {
        twentyPercentLabel.backgroundColor = UIColor(named: "GreenTheme") ?? .green
        twentyPercentLabel.setTitleColor(UIColor.white, for: .normal)
        fifteenPercentLabel.backgroundColor = UIColor.white
        tenPercentLabel.backgroundColor = UIColor.white
    }
    
    @IBAction func doneButtonDidTapped(_ sender: Any) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Dani"
        //content.subtitle = "Please take care"
        content.body = "On the way to SilverlakeFarmers Market"
        content.sound = UNNotificationSound.default
        do{
            content.attachments = try
                [UNNotificationAttachment(identifier: "Driver", url: createLocalUrl(forImageNamed: "Driver")!, options: nil)]
        } catch{
            
        }
        content.threadIdentifier = "local notification temp"
        
        let date = Date(timeIntervalSinceNow: 1)
        let dataComponents = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dataComponents, repeats: false)
        let request = UNNotificationRequest.init(identifier: "content", content:content, trigger: trigger)
        center.add(request) { (error) in
            if error != nil {
                print(error)
            }
        }
    }
    @IBAction func fifteenButtonDidTapped(_ sender: Any) {
        fifteenPercentLabel.backgroundColor = UIColor(named: "GreenTheme") ?? .green
        fifteenPercentLabel.setTitleColor(UIColor.white, for: .normal)
        twentyPercentLabel.backgroundColor = UIColor.white
        tenPercentLabel.backgroundColor = UIColor.white
    }
    @IBAction func tenButtonDidTapped(_ sender: Any) {
        tenPercentLabel.backgroundColor = UIColor(named: "GreenTheme") ?? .green
        tenPercentLabel.setTitleColor(UIColor.white, for: .normal)
        twentyPercentLabel.backgroundColor = UIColor.white
        fifteenPercentLabel.backgroundColor = UIColor.white
    }
    
    func makeRounded() {
        DriverImage.layer.borderWidth = 1
        DriverImage.layer.masksToBounds = false
        DriverImage.layer.borderColor = UIColor.black.cgColor
        DriverImage.layer.cornerRadius = DriverImage.frame.height/2 //This will change with corners of image and height/2 will make this circle shape
        DriverImage.clipsToBounds = true
    }
    
    func createLocalUrl(forImageNamed name: String) -> URL? {
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = cacheDirectory.appendingPathComponent("\(name).png")
        let path = url.path
        
        guard fileManager.fileExists(atPath: path) else {
            guard let image = UIImage(named: name),
                  let data = image.pngData()
            else { return nil }
            fileManager.createFile(atPath: path, contents: data, attributes: nil)
            return url
        }
        return url
    }
    
}
