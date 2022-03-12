//
//  ProfileViewController.swift
//  Harvest
//
//  Created by Ricardo Lee on 2021/2/13.
//

import UIKit
import FirebaseUI
import FirebaseAuth

let greentheme = UIColor(named: "GreenTheme")
let borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var orderHistoryView: UIView!
    @IBOutlet weak var savedView: UIView!
    @IBOutlet weak var orderBtn: UIButton!
    @IBOutlet weak var savedBtn: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    
    private var userName = String("default name")
    var size : CGFloat = 0
    let storageRef = Storage.storage().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        size = view.frame.size.width
        // Do any additional setup after loading the view.
        
        loadCustomer()
        
        // set button border
        orderBtn.layer.borderWidth = 1
        orderBtn.layer.borderColor = borderColor.cgColor
        orderBtn.layer.cornerRadius = 10
        savedBtn.layer.borderWidth = 1
        savedBtn.layer.borderColor = borderColor.cgColor
        savedBtn.layer.cornerRadius = 10
        
        orderHistoryView.alpha = 1.0
        savedView.alpha = 0.0
        
        profileImageView.cornerRadius(cornerRadius: 40)
        profileImageView.clipsToBounds = true
        profileImageView.layer.masksToBounds = true
    }
    
    func updateBtn(_ btn: UIButton, _ state: CGFloat){
        if(state == 1){
            btn.isSelected = true
            btn.backgroundColor = greentheme
            
//            btn.setTitleColor(.white, for: .selected)
        }
        else{
            btn.isSelected = false
            btn.isHighlighted = false
            btn.backgroundColor = .white

//            btn.setTitleColor(greentheme, for: .normal)
        }
    }
    
    @IBAction func didChangeIndex(_ sender: UIButton) {
        sender.tapAnimation {
            self.switchIndex(sender: sender)
        }
        
    }
    
    func switchIndex(sender: UIButton) {
        if(sender == orderBtn){
            // switch view
            
            orderHistoryView.alpha = 1.0
            savedView.alpha = 0.0
        }
        else{
            
            orderHistoryView.alpha = 0.0
            savedView.alpha = 1.0
        }
        
        updateBtn(orderBtn, orderHistoryView.alpha)
        updateBtn(savedBtn, savedView.alpha)
    }
    
    @IBAction func buttonBackPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func loadCustomer() {
        DatabaseManager.shared.retrieveCustomer { [weak self] (customer) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.userName = customer.firstName + " " + customer.lastName
            // Load customer image
            let imgRef = strongSelf.storageRef.child(customer.imageUrl)
            let placeholderImg = UIImage(named: "placeholder")
            strongSelf.profileImageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
            DispatchQueue.main.async{
                strongSelf.userNameLabel.text = strongSelf.userName
            }
        }
    }
    
    @IBAction func profileButtonPressed(_ sender: UIButton) {
        sender.tapAnimation {
            do {
                try Auth.auth().signOut()
                let vc = self.storyboard?.instantiateViewController(identifier: "HomeNavigationController") as! UINavigationController
                self.navigationController?.showDetailViewController(vc, sender: nil)
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
        }
    }
    
}
