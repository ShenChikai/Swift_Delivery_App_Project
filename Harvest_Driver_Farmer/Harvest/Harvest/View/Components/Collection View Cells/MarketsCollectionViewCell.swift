//
//  MarketsCollectionViewCell.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/3/19.
//

import UIKit
import Firebase

class MarketsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var marketImageView: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var marketNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var seeVendorsButton: RoundButton!
    @IBOutlet weak var saveButton: RoundButton!
    
    var market: Market?
    var saveButtonCompletion: ((Market, Bool) -> Void)?
    var seeVendorButtonAction: ((Market) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func saveButtonPressed(_ sender: RoundButton) {
        sender.tapAnimation {
            sender.isSelected = !sender.isSelected
            
            guard let market = self.market else {
                return
            }
            if market.isSaved {
                DatabaseManager.shared.removeMarketFromSaved(market: market, completion: self.saveButtonCompletion)
            } else {
                DatabaseManager.shared.addMarketToSaved(market: market, completion: self.saveButtonCompletion)
            }
        }
    }
    
    @IBAction func seeVendorButtonPressed(_ sender: RoundButton) {
        guard let market = market, let action = seeVendorButtonAction else {
            print("Market or action is nil.")
            return
        }
        sender.tapAnimation {
            action(market)
        }
    }
    
}
