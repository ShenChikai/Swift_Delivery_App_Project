//
//  FarmDetailViewController.swift
//  Harvest
//

import Foundation
import UIKit
import ValueStepper

class FarmDetailViewController: UIViewController {
    
    var fruitName_: String!
    var priceName_ : String!
    var Image_ : UIImage!
    var description_ : String!
    var cost : Double = 0.0
    var receipt = ReceiptModel.shared
    var count : Double = 1.0
    var farmID : String!
    
    var produce: Produce!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBAction func backButtonDidTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBOutlet weak var fruitImage: UIImageView!
    @IBOutlet weak var fruitNameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var valueStepper: ValueStepper!
    @IBOutlet weak var addButton: RoundButton!
    
    @IBAction func addFruitToBag(_ sender: RoundButton) {
        sender.tapAnimation {
            self.addToBag()
        }
    }
    
    @IBAction func valueStepperChanged(_ sender: ValueStepper) {
        addButton.setTitle("Add to bag \(String(format: "$%.1f", sender.value * cost))", for: .normal)
        count = sender.value
    }
    
    override func viewDidLoad() {
        fruitImage.image = Image_
        fruitNameLabel.text = fruitName_
        priceLabel.text = priceName_
        descriptionLabel.text = description_
        cost = Double(priceName_)!
        addButton.setTitle("Add to bag \(String(format: "$%.1f", cost))", for: .normal)
        print(farmID)
    }
    
    func addToBag() {
        //receipt.insert(item: BoughtItem(produceName: fruitName_, price: count * cost, num: Int(count), unitPrice: cost))
        receipt.totalCost += count * cost
        if count == 0 {
            // TODO: remove from cart
            for i in 0..<ReceiptModel.shared.list.count {
                if ReceiptModel.shared.list[i].produceName.elementsEqual(fruitNameLabel.text!) {
                    ReceiptModel.shared.list.remove(at: i)
                }
            }
        } else {
            // TODO: update cart
            for i in 0..<ReceiptModel.shared.list.count {
                 // if already in the list
                if ReceiptModel.shared.list[i].produceName.elementsEqual(fruitNameLabel.text!) {
                    ReceiptModel.shared.totalCost -= ReceiptModel.shared.list[i].price
                    ReceiptModel.shared.list.remove(at: i)
                    ReceiptModel.shared.insert(item: BoughtItem(produceName: fruitNameLabel.text!, price: Double(priceLabel.text!)! * Double(count), num: Int(count), unitPrice: Double(priceLabel.text!)!, farmID: farmID, imageUrl: produce.image_url))
                    ReceiptModel.shared.totalCost += Double(priceLabel.text!)!
                    self.navigationController?.popViewController(animated: true)
                    return
                }
            }
        }
        receipt.insert(item: BoughtItem(produceName: fruitName_, price: count * cost, num: Int(count), unitPrice: cost, farmID: farmID, imageUrl: produce.image_url))
        self.navigationController?.popViewController(animated: true)
    }
    
}
