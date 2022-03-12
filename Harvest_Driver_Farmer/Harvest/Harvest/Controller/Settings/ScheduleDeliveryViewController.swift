//
//  ScheduleDeliveryViewController.swift
//  Harvest
//
//  Created by jiayang on 2021/4/14.
//

import Foundation
import UIKit

class ScheduleDeliveryViewController: UIViewController {
    
    @IBOutlet weak var dataPicker: UIDatePicker!
    @IBOutlet weak var TitleLabel: UILabel!
    override func viewDidLoad() {
            dataPicker.preferredDatePickerStyle = UIDatePickerStyle.wheels
    }
    @IBAction func datePickerChanged(_ sender: Any) {
        let dateFormatter = DateFormatter()

            dateFormatter.dateStyle = DateFormatter.Style.short
            dateFormatter.timeStyle = DateFormatter.Style.short

            let strDate = dateFormatter.string(from: dataPicker.date)
            TitleLabel.text = strDate
    }
    
    @IBAction func scheduleButtonDidTapped(_ sender: Any) {
    }
}
