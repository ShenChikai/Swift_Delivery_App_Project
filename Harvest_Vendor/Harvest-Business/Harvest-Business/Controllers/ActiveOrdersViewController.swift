//
//  ActiveOrdersViewController.swift
//  Harvest-Business
//
//  Created by Zixuan Li on 2021/4/15.
//

import Foundation
import UIKit
import Firebase
import FirebaseStorage
import NVActivityIndicatorView

class ActiveOrdersViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let storageRef = Storage.storage().reference()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var activeOrders = [Order]()
    var allOrders = [Order]()
    var deliverySession: DeliverySession!
    var completion: (() -> Void)!
    
    let loading = NVActivityIndicatorView(frame: .zero, type: .ballRotateChase, color: UIColor(named: "GreenTheme"), padding: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.collectionView.register(UINib(nibName: "ActiveOrdersCellView", bundle: Bundle(for: ActiveOrdersCellView.self)), forCellWithReuseIdentifier: "MyCell")
        
        // add loading animation
        loading.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(loading)
        NSLayoutConstraint.activate([
            loading.widthAnchor.constraint(equalToConstant: 50),
            loading.heightAnchor.constraint(equalToConstant: 50),
            loading.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
        //        loading.startAnimating()
        //
        //        // load active orders from db
        //        loadOrders()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        filterOrders()
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - loading active orders
    var seconds: Int = 0
    var timer = Timer()
    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true) // 1 sec as interval
    }
    
    @objc func timerCounter() {
        seconds += 1
    }
    
    /// Previously used to load orders from database
    private func loadOrders() {
        // retrieve until 5 sec later
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            DatabaseManager.shared.retrieveActiveOrders { [weak self] (order) in
                guard let strongSelf = self else { return }
                strongSelf.activeOrders.append(order)
                DispatchQueue.main.async {
                    strongSelf.collectionView.reloadData()
                }
                if(strongSelf.activeOrders.count > 0) {
                    strongSelf.loading.stopAnimating()
                    return
                }
            }
        }
    }
    
    private func filterOrders() {
        self.activeOrders = allOrders.filter({ (order) -> Bool in
            return !order.pickupStatus
        })
        if self.activeOrders.count == 0 {
            DatabaseManager.shared.incrementCurrentSessionStep(id: deliverySession.id) { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.deliverySession.incrementStep()
                strongSelf.completion()
                strongSelf.navigationController?.popViewController(animated: true)
            }
        } else {
            self.collectionView.reloadData()
        }
    }
    
    // MARK: - extensions
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activeOrders.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath) as! ActiveOrdersCellView
        
        let customer = activeOrders[indexPath.item].customer
        
        // load image from cloud
        let imgRef = storageRef.child(customer.imageUrl)
        let imageView: UIImageView = cell.customerAvatar
        let placeholderImg = UIImage(named: "placeholder")
        imageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = imageView.frame.size.height / 2
        imageView.clipsToBounds = true
        
        cell.customerName.text = customer.firstName + " " + customer.lastName
        cell.totalNum.text = "\(activeOrders[indexPath.item].numOfItems) " + (activeOrders[indexPath.item].numOfItems > 1 ? "items" : "item")
        cell.totalEarn.text = String(format: "$%.2f", activeOrders[indexPath.item].totalEarned)
        
        // add rounded border
        let layer = cell.orderStackView.layer
        cell.orderStackView.customize(cornerRadius: 15, borderColor: UIColor(.gray).cgColor, borderWidth: 2, opacity: 0.2)
        layer.masksToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.cellForItem(at: indexPath)?.tapAnimation {
            print("Selected active order list cell")
            
            // add tapped action to send market name, addr and produce list
            let activeOrder = self.activeOrders[indexPath.item]
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "OrderDetailsViewController") as! OrderDetailsViewController
            vc.order = activeOrder
            vc.deliverySession = self.deliverySession
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: self.view.frame.width, height: 80)
    }
    
}
