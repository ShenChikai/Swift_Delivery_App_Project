//
//  VendorsCollectionViewController.swift
//  Harvest
//
//  Created by Jiayang Li on 2021/2/7.
//  Modified by Zixuan Li on 2021/3/8

import Foundation
import UIKit

class VendorsCollectionViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var marketLabel: UILabel!
    
    @IBOutlet weak var activeAddress: RoundButton!
    
    var market: Market?
    
    private var allVendors = [
        "Veggie Vendors": [Farm](),
        "Fruit Vendors": [Farm](),
    ]
    
    private var activeAddressText = "Unknown"
    private var myLat = 34.0224
    private var myLon = 118.2851

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        var marketid = "s6GynZT10muUMDWnyR6O"
        marketLabel.text = market!.title
        
        for category in categories {
            DatabaseManager.shared.retrieveFarms (with: category, marketRef: market!.ref!){ [weak self] (farm) in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.allVendors[category]?.append(farm)
                DispatchQueue.main.async {
                    strongSelf.tableView.reloadData()
                }
            }
        }
        
        // load active addr
        DatabaseManager.shared.retrieveActiveAddress { [weak self] (title, subtitle, lat, lon, apt, building, instruction) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.activeAddressText =  title
            strongSelf.myLat =  lat
            strongSelf.myLon =  lon
            DispatchQueue.main.async{
                strongSelf.activeAddress.setTitle(strongSelf.activeAddressText, for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ReceiptModel.shared.market = market
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    var categories = ["Veggie Vendors", "Fruit Vendors"]

    @IBAction func infoButtonPressed(_ sender: UIButton) {
        // TODO
    }
    
    @IBAction func addressButtonPressed(_ sender: RoundButton) {
        sender.tapAnimation {
            let vc = self.storyboard?.instantiateViewController(identifier: "DeliveryAddressViewController") as! DeliveryAddressViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension VendorsCollectionViewController: UITableViewDelegate {
    
}

extension VendorsCollectionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as! VendorsTableViewCell
        cell.categoryLabel.text = categories[indexPath.row]
        cell.vendors = allVendors[categories[indexPath.row]] ?? allVendors["Veggie Vendors"]!
        // dump(cell.vendors)
        cell.width = view.frame.size.width / 2 - 10
        cell.collectionView.reloadData()
        // add tapped action to send farm name and img
        cell.vendorTappedAction = { farmname, image_url, farmid in
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "ProducesCollectionViewController") as? ProducesCollectionViewController
            vc?.farmname = farmname
            vc?.image_url = image_url
            vc?.farmID = farmid
            print("farmID acquired:", farmid)
            print("tapped cell \(String(describing: vc?.farmname))")
            self.navigationController?.pushViewController(vc!, animated: true)
  
        }
        
        return cell
    }
    
    
}
