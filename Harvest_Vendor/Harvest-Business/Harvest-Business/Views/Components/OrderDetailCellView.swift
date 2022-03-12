//
//  OrderDetailCellView.swift
//  Harvest-Business
//
//  Created by Zixuan Li on 2021/4/16.
//

import UIKit
import Firebase

class OrderDetailCellView: UICollectionViewCell {
    
    @IBOutlet weak var produceCheck: UIButton!
    @IBOutlet weak var produceStack: UIStackView!
    @IBOutlet weak var produceImg: UIImageView!
    @IBOutlet weak var produceName: UILabel!
    @IBOutlet weak var produceQuantity: UILabel!
    @IBOutlet weak var unitPrice: UILabel!
    
    var checkAction: ((Int) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    /// switch on/off checker
    @IBAction func checkOrder(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        checkAction?(sender.isSelected ? 1 : -1)
    }
}

