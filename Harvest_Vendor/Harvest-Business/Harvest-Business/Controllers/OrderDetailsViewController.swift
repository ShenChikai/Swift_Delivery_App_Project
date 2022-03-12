//
//  OrderDetailsViewController.swift
//  Harvest-Business
//
//  Created by Zixuan Li on 2021/4/16.
//

import Foundation
import UIKit
import Firebase

class OrderDetailsViewController: UIViewController {
    
    let storageRef = Storage.storage().reference()
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var orderNumLabel: RoundButton!
    @IBOutlet weak var marketNameLabel: UILabel!
    @IBOutlet weak var marketAddressLabel: UILabel!
    @IBOutlet weak var completeOrderButton: RoundButton!
    
    var order: Order! // list of produces for each farm
    var deliverySession: DeliverySession!
    var pickedCount = 0
    var totalCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        let nib = UINib(nibName: "OrderDetailCellView", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "MyCell")
        
        orderNumLabel.setTitle("Order #" + String(order.id.prefix(6)), for: .disabled) //only use first 6 digits of orderID
        marketNameLabel.text = order.marketName
        marketAddressLabel.text = order.marketAddressTitle
        completeOrderButton.isEnabled = false
        completeOrderButton.alpha = 0.5
        pickedCount = 0
        totalCount = 0
        let farmIDToOrder = order.farmIDToOrder
        for farm in farmIDToOrder {
            totalCount += (farm["shopping_list"] as! [[String: Any]]).count
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func completeButtonPressed(_ sender: UIButton) {
        sender.tapAnimation {
            self.completeOrder()
        }
    }
    
    func completeOrder() {
        DatabaseManager.shared.updatePickupStatus(orderId: order.id, deliverySessionId: deliverySession.id, status: true) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.order.pickupStatus = true
            strongSelf.navigationController?.popViewController(animated: true)
        }
    }
    
}

extension OrderDetailsViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return order.farmIDToOrder.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (order.farmIDToOrder[section]["shopping_list"] as! [[String: Any]]).count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as! FarmSectionHeader
        if indexPath.section < order.farmIDToOrder.count {
            DatabaseManager.shared.farmIDtoName(order.farmIDToOrder[indexPath.section]["farm"] as! String) { (farmName) in
                sectionHeader.sectionNameLabel.text = farmName
            }
        } else {
            print("Error in viewForSupplementaryElementOfKind")
            sectionHeader.sectionNameLabel.text = "UNKNOWN"
        }
        
        return sectionHeader
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath) as! OrderDetailCellView

        let farmSection = order.farmIDToOrder[indexPath.section]
        let produces = farmSection["shopping_list"] as! [[String: Any]]
        let produce = produces[indexPath.item]
        
        // load image from cloud
        let imgRef = storageRef.child(produce["image_url"] as? String ?? "")
        let imageView: UIImageView = cell.produceImg
        let placeholderImg = UIImage(named: "placeholder")
        imageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        
        cell.produceName.text = (produce["produce_name"] as! String)
        cell.produceQuantity.text = "x \(produce["num"] as! Int)"
        cell.unitPrice.text = String(format: "$%.2f", produce["unit_price"] as! Double)
        
        // add rounded border
        let layer = cell.produceStack.layer
        cell.produceStack.customize(cornerRadius: 15, borderColor: UIColor(.gray).cgColor, borderWidth: 2, opacity: 0.2)
        layer.masksToBounds = true
        
        // Add check action
        cell.checkAction = { [weak self] (step) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.pickedCount += step
            if strongSelf.pickedCount == strongSelf.totalCount {
                strongSelf.completeOrderButton.isEnabled = true
                strongSelf.completeOrderButton.alpha = 1
            } else {
                strongSelf.completeOrderButton.isEnabled = false
                strongSelf.completeOrderButton.alpha = 0.5
            }
        }
        
        return cell
    }
    
}

extension OrderDetailsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // TODO
        print("Selected order detail cell")
    }
    
}

extension OrderDetailsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: self.view.frame.width, height: 100)
    }
    
}
