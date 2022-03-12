//
//  VendorsTableViewCell.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/2/28.
//  Modified by Zixuan Li on 2021/4/17.

import UIKit
import Firebase

class VendorsTableViewCell: UITableViewCell {
    
    let storageRef = Storage.storage().reference()
    
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var vendors: [Farm] = []
    var width: CGFloat = 0
    
    var vendorTappedAction: ((String, String, String)->Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

extension VendorsTableViewCell: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected cell \(vendors[indexPath.row].farmName)")
        let vendor = vendors[indexPath.row]
        collectionView.cellForItem(at: indexPath)?.tapAnimation {
            // pass data to produce page
            self.vendorTappedAction?(vendor.farmName, vendor.image_url, vendor.farmId)
        }
    }
    
}


extension VendorsTableViewCell: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return vendors.count;
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VendorsCell", for: indexPath) as! VendorCollectionViewCell
        
        // load image from cloud
        let imgRef = storageRef.child(vendors[indexPath.row].image_url)
        let imageView: UIImageView = cell.farmImageView
        let placeholderImg = UIImage(named: "placeholder")
        imageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 14
        imageView.clipsToBounds = true
        
        cell.farmLabel.text = vendors[indexPath.row].farmName
        
        return cell
    }
}

extension VendorsTableViewCell: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: width, height: 240)
    }
}
