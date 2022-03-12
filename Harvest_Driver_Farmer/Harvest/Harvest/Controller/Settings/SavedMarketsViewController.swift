//
//  SavedMarketsViewController.swift
//  Harvest
//
//  Created by Zixuan Li on 2021/2/13.
//

import Foundation
import UIKit
import FirebaseUI

class SavedMarketsViewController: UIViewController {
    
    let storageRef = Storage.storage().reference()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var savedMarkets = [Market]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        
        // load saved markets
        DatabaseManager.shared.retrieveSavedMarkets { [weak self] (market) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.savedMarkets.append(market)
            DispatchQueue.main.async {
                strongSelf.collectionView.reloadData()
            }
        }
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let nib = UINib(nibName: "MarketsCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "MyCell")
    }
    
}

extension SavedMarketsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // TODO
        print("Selected cell")
    }
    
}

extension SavedMarketsViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedMarkets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath) as! MarketsCollectionViewCell
        let markets: [Market] = savedMarkets
        
        // load image from cloud
        let imgRef = storageRef.child(markets[indexPath.item].image_url)
        let imageView: UIImageView = cell.marketImageView
        let placeholderImg = UIImage(named: "placeholder")
        imageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
        
//        cell.marketImageView.image = UIImage(named:"placeholder")  // TODO: fix it
        cell.marketImageView.layer.cornerRadius = 10
        cell.marketImageView.clipsToBounds = true
        cell.marketNameLabel.text = markets[indexPath.item].title
        cell.descriptionLabel.text = markets[indexPath.item].description
        cell.distanceLabel.text = markets[indexPath.item].distance
        cell.saveButton.isSelected = markets[indexPath.item].isSaved
        cell.market = markets[indexPath.item]
        cell.saveButtonCompletion = { [weak self] (market, isAddition) in
            guard !isAddition, let strongSelf = self else {
                return
            }
            strongSelf.savedMarkets = strongSelf.savedMarkets.filter { (savedMarket) -> Bool in
                return savedMarket.ref != market.ref
            }
            DispatchQueue.main.async {
                strongSelf.collectionView.reloadData()
            }
        }
        cell.seeVendorButtonAction = { [weak self] (market) in
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
                let vc = strongSelf.storyboard?.instantiateViewController(identifier: "VendorsCollectionViewController") as! VendorsCollectionViewController
                vc.market = market
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        return cell
    }
    
}

extension SavedMarketsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: self.view.frame.width, height: 280)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
}
