//
//  ProducesByCategoryViewController.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/3/3.
//

import UIKit
import FirebaseUI

class ProducesSingleCategoryViewController: UIViewController {

    let storageRef = Storage.storage().reference()

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var categoryLabel: UILabel!
    
    private let sectionInsets = UIEdgeInsets(top: 0.0, left: 16, bottom: 0.0, right: 16)

    var allProduces = [String: [Produce]]()
    
    // testing prepare
    var farmID = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = UICollectionViewFlowLayout()
        
        let nib = UINib(nibName: "ProducesCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "ProduceCell")
    }
    
}

extension ProducesSingleCategoryViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // TODO
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destination = storyboard.instantiateViewController(withIdentifier: "farmDetail") as! FarmDetailViewController
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProduceCell", for: indexPath) as! ProducesCollectionViewCell
        let produce = (allProduces[categoryLabel.text!] ?? [])[indexPath.row]
        // load image from cloud
        let imgRef = storageRef.child(produce.image_url)
        let imageView: UIImageView = cell.imageView
        let placeholderImg = UIImage(named: "placeholder")
        imageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
        
        destination.Image_ = imageView.image
        destination.description_ = produce.description
        destination.fruitName_ = produce.name
        destination.priceName_ = produce.unitPrice.description
        destination.cost = produce.unitPrice
        destination.farmID = farmID
        destination.produce = produce
        navigationController?.pushViewController(destination, animated: true)
        print("Selected cell")
    }
    
}

extension ProducesSingleCategoryViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (allProduces[categoryLabel.text!] ?? []).count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProduceCell", for: indexPath) as! ProducesCollectionViewCell
        let produce = (allProduces[categoryLabel.text!] ?? [])[indexPath.row]

        // load image from cloud
        let imgRef = storageRef.child(produce.image_url)
        let imageView: UIImageView = cell.imageView
        let placeholderImg = UIImage(named: "placeholder")
        imageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
        
        cell.nameLabel.text = produce.name
        cell.priceLabel.text = produce.unitPrice.description
        cell.descriptionLabel.text = produce.description
        cell.farmID = farmID
        cell.produce = produce
        return cell
    }
    
}

extension ProducesSingleCategoryViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let paddingSpace = sectionInsets.left * 4
        let availableWidth = view.frame.width - paddingSpace
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
