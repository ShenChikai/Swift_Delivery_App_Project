//
//  ProducesTableViewCell.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/3/4.
//

import UIKit
import FirebaseUI

class ProducesTableViewCell: UITableViewCell {
    
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    let storageRef = Storage.storage().reference()
    var produceAllVc = ProducesDisplayAllViewController()
    var produces: [Produce] = []
    var width: CGFloat = 0
    var farmID = String()
    private let sectionInsets = UIEdgeInsets(top: 0.0, left: 16, bottom: 0.0, right: 16)

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        collectionView.delegate = self
        collectionView.dataSource = self
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .horizontal
//        collectionView.collectionViewLayout = layout
        
        let nib = UINib(nibName: "ProducesCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "ProduceCell")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

extension ProducesTableViewCell: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ProducesCollectionViewCell
        cell.tapAnimation {
            let produce = self.produces[indexPath.row]
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let destination = storyboard.instantiateViewController(withIdentifier: "farmDetail") as! FarmDetailViewController
            //self.navigationController?.pushViewController(destination, animated:true)
            
            let imgRef = self.storageRef.child(produce.image_url)
            let imageView: UIImageView = cell.imageView
            let placeholderImg = UIImage(named: "placeholder")
            imageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
            
            destination.Image_ = imageView.image
            destination.description_ = produce.description
            destination.fruitName_ = produce.name
            destination.priceName_ = produce.unitPrice.description
            destination.farmID = self.farmID
            destination.produce = produce
            
            self.produceAllVc.navigationController?.pushViewController(destination, animated: true)
        }
        
    }
    
}

extension ProducesTableViewCell: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return produces.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProduceCell", for: indexPath) as! ProducesCollectionViewCell
        let produce = produces[indexPath.row]
        cell.nameLabel.text = produce.name
        cell.priceLabel.text = produce.unitPrice.description
        cell.descriptionLabel.text = produce.description
        cell.farmID = farmID
        cell.produce = produce
        
        // load image from cloud
        let imgRef = storageRef.child(produce.image_url)
        let imageView: UIImageView = cell.imageView
        let placeholderImg = UIImage(named: "placeholder")
        imageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
        
        return cell
    }
    
}

extension ProducesTableViewCell: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let paddingSpace = sectionInsets.left * 4
        let availableWidth = width - paddingSpace
        let widthPerItem  = floor(availableWidth / 3)

        return CGSize(width: widthPerItem, height: 180)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
}
