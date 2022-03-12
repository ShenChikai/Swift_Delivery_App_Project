//
//  TestCollectionViewCell.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/3/4.
//

import UIKit
import ValueStepper

class ProducesCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var plusButton: RoundButton!
    @IBOutlet weak var valueStepper: ValueStepper!
    
    var itemCount: Int = 0
    var farmID = String()
    var produce: Produce!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    
        valueStepper.isHidden = true
        itemCount = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(dismissValueStepper(_:)), name: .produceBackgroundTapped, object: nil)
    }

    @IBAction func plusButtonPressed(_ sender: RoundButton) {
        sender.tapAnimation {
            if self.itemCount == 0 {
                self.itemCount += 1
            }
            NotificationCenter.default.post(name: .produceBackgroundTapped, object: self)
            self.updateUIToValue(value: self.itemCount)
            self.toggleValueStepper()
            print(self.farmID)
            // TODO: add to cart
            for i in 0..<ReceiptModel.shared.list.count {
                 // if already in the list
                if ReceiptModel.shared.list[i].produceName.elementsEqual(self.nameLabel.text!) {
                    ReceiptModel.shared.list[i].num = self.itemCount
    //                ReceiptModel.shared.totalCost +=  ReceiptModel.shared.list[i].unitPrice
                    return
                }
            }
            // if not in the list
            ReceiptModel.shared.insert(item: BoughtItem(produceName: self.nameLabel.text!, price: Double(self.priceLabel.text!)! * Double(self.itemCount), num: self.itemCount, unitPrice: Double(self.priceLabel.text!)!, farmID: self.farmID, imageUrl: self.produce.image_url))
            ReceiptModel.shared.totalCost += Double(self.priceLabel.text!)!
            
        }
        
    }
    
    @IBAction func stepperValueChanged(_ sender: ValueStepper) {
        itemCount = Int(sender.value)
        updateUIToValue(value: itemCount)
        if itemCount == 0 {
            toggleValueStepper()
            // TODO: remove from cart
            for i in 0..<ReceiptModel.shared.list.count {
                if ReceiptModel.shared.list[i].produceName.elementsEqual(nameLabel.text!) {
                    ReceiptModel.shared.totalCost -= ReceiptModel.shared.list[i].price
                    ReceiptModel.shared.list.remove(at: i)
                }
            }
        } else {
            // TODO: update cart
            for i in 0..<ReceiptModel.shared.list.count {
                 // if already in the list
                if ReceiptModel.shared.list[i].produceName.elementsEqual(nameLabel.text!) {
                    ReceiptModel.shared.totalCost -= ReceiptModel.shared.list[i].price
                    ReceiptModel.shared.list.remove(at: i)
                    ReceiptModel.shared.insert(item: BoughtItem(produceName: nameLabel.text!, price: Double(priceLabel.text!)! * Double(itemCount), num: itemCount, unitPrice: Double(priceLabel.text!)!, farmID: farmID, imageUrl: produce.image_url))
                    ReceiptModel.shared.totalCost += Double(priceLabel.text!)! * (valueStepper.value)
                }
            }
        }
    }
    
    /// Set plus button value to "value"
    func updateUIToValue(value: Int) {
        if value == 0 {
            DispatchQueue.main.async {
                self.plusButton.setTitle("+", for: .normal)
                self.plusButton.titleLabel?.font = UIFont(name: "Roboto", size: 30)
                self.valueStepper.value = Double(value)
            }
        } else {
            DispatchQueue.main.async {
                self.plusButton.setTitle("\(value)", for: .normal)
                self.plusButton.titleLabel?.font = UIFont(name: "Roboto", size: 18)
                self.valueStepper.value = Double(value)
            }
        }
    }
    
    /// Display or hide value stepper
    func toggleValueStepper() {
        if valueStepper.isHidden {
            DispatchQueue.main.async {
                self.plusButton.isHidden = true
                self.valueStepper.isHidden = false
            }
        } else {
            DispatchQueue.main.async {
                self.valueStepper.isHidden = true
                self.plusButton.isHidden = false
            }
        }
    }
    
    /// Triggered when background tapped
    @objc func dismissValueStepper(_ notification: Notification) {
        guard let object = notification.object, !valueStepper.isHidden else {
            return
        }
        // Click other cell's button
        if let cell = object as? ProducesCollectionViewCell, cell != self {
            toggleValueStepper()
            return
        }
        // Click background
        if let recognizer = object as? UITapGestureRecognizer {
            let point = recognizer.location(in: self.contentView)
            if !valueStepper.frame.contains(point) {
                toggleValueStepper()
                return
            }
        }
        
    }
    
}
