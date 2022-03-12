//
//  ProducesCollectionViewController.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/3/2.
//

import UIKit
import FirebaseUI

class ProducesCollectionViewController: UIViewController {

    var farmname = String()
    var image_url = String()
    var farmID = String()
    
    let storageRef = Storage.storage().reference()
    
    var displayAll: ProducesDisplayAllViewController!
    var displaySingle: ProducesSingleCategoryViewController!
    
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var categoryTF: UITextField!
    @IBOutlet weak var farmName: UILabel!
    @IBOutlet weak var singleCategoryContainerView: UIView!
    @IBOutlet weak var displayAllContainerView: UIView!
    @IBOutlet weak var viewBagButton: RoundButton!
    
    private var pickerOptions: [String] = ["Categories", "In Season", "Leafy Greens"]
    private var pickerSelectedIdx = 0
    var allProduces = [String: [Produce]]()
    var categories: [String] = ["Popular Items", "In Season", "Leafy Greens"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ProducesCollection, FarmID: ", farmID, "; ImageUrl: ", image_url)
        
        DispatchQueue.main.async {
            let imgRef = self.storageRef.child(self.image_url)
            let placeholderImg = UIImage(named: "placeholder")
            self.headerImageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg) { (placeholderIMG, err, imgCacheType, url) in
                self.headerImageView.image = self.headerImageView.image?.blur(50)
            }
        }
        
        farmName.text = farmname
        
        createPickerView()
        configureTextField()
        
        allProduces = [String: [Produce]]()
        
        
        for category in categories {
            DatabaseManager.shared.retrieveProduces(with: category, farmID: farmID) { [weak self] (produce) in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.allProduces[category, default: []].append(produce)
                DispatchQueue.main.async {
                    strongSelf.displaySingle.allProduces = strongSelf.allProduces
                    strongSelf.displayAll.allProduces = strongSelf.allProduces
                    strongSelf.displayAll.tableView.reloadData()
                    strongSelf.displaySingle.collectionView.reloadData()
                }
            }
        }
        
        
        // MARK: Admin Mass Insert Produce Script
//        let fruitList = ["watermelon","strawberries","raspberries", "apricots", "pineapple","peach_yellow","peach_white","mango","limes","lemons","kiwi","cherry","grapes_green","cantaloupe","blackberry","banana","apricots_dried","apple_green","orange","blood_orange"]
//        let vegeList = ["spinach","peas","parsley","mint","matcha","lettuce","kale","cilantro","celery","cauliflower","carrots","asparagus","bell_pepper","bok_choy","broccoli","brussel_sprouts","cabbage"]
//        let popularList = ["walnuts","tomato","potato","olive_oil","milk","lavender","dates","eggs","butter","avocado","beef","honey","hummus","jam"]
//        let priceList = [1,1.3,1.5,2,2.2,2.6,3,3.5,3.9,4,4.4,4.5,5,5.5,5.9]
//        for fruit in fruitList {
//            let rnd_int = Int.random(in: 0...10)
//            if (rnd_int <= 3) {
//                // 30% change to insert this item
//                let rnd_price = priceList[Int.random(in: 0...(priceList.count-1))]
//                DatabaseManager.shared.massInsertProduce(farm_id: farmID, name: fruit, categoryArr: ["In Season"], unit_price: rnd_price)
//            }
//        }
//        for vege in vegeList {
//            let rnd_int = Int.random(in: 0...10)
//            if (rnd_int <= 3) {
//                // 30% change to insert this item
//                let rnd_price = priceList[Int.random(in: 0...(priceList.count-1))]
//                DatabaseManager.shared.massInsertProduce(farm_id: farmID, name: vege, categoryArr: ["Leafy Greens"], unit_price: rnd_price)
//            }
//        }
//        for popular in popularList {
//            let rnd_int = Int.random(in: 0...10)
//            if (rnd_int <= 3) {
//                // 30% change to insert this item
//                let rnd_price = priceList[Int.random(in: 0...(priceList.count-1))]
//                DatabaseManager.shared.massInsertProduce(farm_id: farmID, name: popular, categoryArr: ["Popular Items"], unit_price: rnd_price)
//            }
//        }
    }

    // share farmID with child controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ProducesDisplayAllViewController,
           segue.identifier == "displayAll" {
            self.displayAll = vc
            self.displayAll.farmID = farmID
        }
        
        if let vc = segue.destination as? ProducesSingleCategoryViewController,
           segue.identifier == "displaySingle" {
            self.displaySingle = vc
            self.displaySingle.farmID = farmID
        }
    }
    
    private func createPickerView() {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        categoryTF.inputView = pickerView
        
        // Add tool bar
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.doneButtonPressed))
        toolBar.setItems([button], animated: true)
        toolBar.isUserInteractionEnabled = true
        categoryTF.inputAccessoryView = toolBar
        
    }
    
    private func configureTextField() {
        categoryTF.delegate = self
        categoryTF.text = pickerOptions[pickerSelectedIdx]
    }
    
    @objc private func doneButtonPressed() {
        view.endEditing(true)
    }

    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func viewBagButtonPressed(_ sender: RoundButton) {
        sender.tapAnimation {
            let vc = self.storyboard?.instantiateViewController(identifier: "ReceiptTableViewController") as! ReceiptTableViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
        categoryTF.resignFirstResponder()
        NotificationCenter.default.post(name: .produceBackgroundTapped, object: sender)
    }
}

extension ProducesCollectionViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("Selected index: \(row)")
        pickerSelectedIdx = row
        categoryTF.text = pickerOptions[pickerSelectedIdx]
    }
    
}

extension ProducesCollectionViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        print("End editing")
        if pickerSelectedIdx == 0 {
            singleCategoryContainerView.isHidden = true
            displayAllContainerView.isHidden = false
        } else {
            DispatchQueue.main.async {
                self.displaySingle.categoryLabel.text = self.pickerOptions[self.pickerSelectedIdx]
                self.displaySingle.collectionView.reloadData()
            }
            displayAllContainerView.isHidden = true
            singleCategoryContainerView.isHidden = false
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
    
}
