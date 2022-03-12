//
//  ActiveOrdersViewCell.swift
//  Harvest-Business
//
//  Created by Zixuan Li on 2021/4/15.
//

import UIKit
import Firebase

class ActiveOrdersCellView: UICollectionViewCell {
    
    @IBOutlet weak var orderStackView: UIStackView!
    @IBOutlet weak var customerAvatar: UIImageView!
    @IBOutlet weak var customerName: UILabel!
    @IBOutlet weak var totalNum: UILabel!
    @IBOutlet weak var totalEarn: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
