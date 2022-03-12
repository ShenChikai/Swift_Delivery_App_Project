//
//  OrderHistoryViewController.swift
//  Harvest
//
//  Created by Zixuan Li on 2021/2/13.
//

import Foundation
import UIKit
import FirebaseUI

class OrderHistoryViewController: UIViewController, UITableViewDelegate,  UITableViewDataSource {

    let storageRef = Storage.storage().reference()
    
    @IBOutlet weak var tableView: UITableView!
    
    private var orders = [ReceiptModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        
        DatabaseManager.shared.retrieveOrders { [weak self] (order) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.orders.append(order)
            DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        view.addSubview(tableView)
    
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor)
            ])
    }

    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return orders.count
        }
        
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrderCell", for: indexPath) as! OrderHistoryViewCell
        
        // load image from cloud
        let imgRef = storageRef.child(orders[indexPath.item].market!.image_url)
        let imageView: UIImageView = cell.CircularImage
        let placeholderImg = UIImage(named: "placeholder")
        imageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
        
        // circular image
        cell.CircularImage.layer.masksToBounds = false
        cell.CircularImage.layer.cornerRadius = cell.CircularImage.frame.height/2
        cell.CircularImage.clipsToBounds = true
        
        // load market name, $, count
        cell.MarketName.text = orders[indexPath.item].market?.title
        cell.NumOfItems.text = "\( orders[indexPath.item].numOfItems) items"
        cell.TotalCost.text = "$\( orders[indexPath.item].totalCost)"
        
        // load order date
        let dateIcon = NSTextAttachment()
        dateIcon.image = UIImage(systemName: "calendar")?.withRenderingMode(.alwaysTemplate)
        dateIcon.image = dateIcon.image?.withTintColor(UIColor.lightGray) //set icon to grey
        // set bound to reposition
        dateIcon.bounds = CGRect(x: 0, y: -5.0, width: dateIcon.image!.size.width, height: dateIcon.image!.size.height)
        let iconString = NSAttributedString(attachment: dateIcon) // create string from icon
        let completeText = NSMutableAttributedString(string:"")
        completeText.append(iconString)
        let dateText = NSAttributedString(string: orders[indexPath.item].getBoughtDate())
        completeText.append(dateText)
        cell.Date.attributedText = completeText
    
        // draw border around label
        cell.Date.layer.borderColor = borderColor.cgColor
        cell.Date.layer.cornerRadius = 10
        cell.Date.layer.borderWidth = 1
        return cell
    }
    
    // offset each row height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
