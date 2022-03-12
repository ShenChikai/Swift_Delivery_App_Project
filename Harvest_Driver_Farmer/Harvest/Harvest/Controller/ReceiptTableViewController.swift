//
//  ReceiptTableViewController.swift
//  Harvest
//
//  Created by bytedance on 2021/2/11.
//

import Foundation
import UIKit
import Stripe
import JGProgressHUD

class ReceiptTableViewController: UITableViewController {
    @IBOutlet weak var deliverToButton: UIButton!
    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var completeOrderButton: RoundButton!
    
    private let hud = JGProgressHUD()
   
    private var activeAddressText = "Unknown"
    private var myLat = 34.0224
    private var myLon = 118.2851
    private var phone_num = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fromButton.setTitle(ReceiptModel.shared.market?.title ?? "Current market", for: .normal)
        
        hud.textLabel.text = "Loading"
        setupNavigationBar()
        
        // load user name
        DatabaseManager.shared.retrieveUserPhone { [weak self] (phone_num) in
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async{
                strongSelf.phone_num = phone_num
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
                strongSelf.deliverToButton.setTitle(strongSelf.activeAddressText, for: .normal)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // load active addr
        DatabaseManager.shared.retrieveActiveAddress { [weak self] (title, subtitle, lat, lon, apt, building, instruction) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.activeAddressText =  title
            strongSelf.myLat =  lat
            strongSelf.myLon =  lon
            DispatchQueue.main.async{
                strongSelf.deliverToButton.setTitle(strongSelf.activeAddressText, for: .normal)
            }
        }
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func setupNavigationBar() {
        self.navigationController?.navigationBar.barTintColor = .white
        
        // Add back button
        let buttonBack = UIButton()
        buttonBack.tintColor = .black
        buttonBack.setImage(UIImage(systemName: "multiply"), for: .normal)
        buttonBack.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: buttonBack)
        
        // Adjust font
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Roboto-Regular", size: 18)!]
    }
    
    @objc func backButtonPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func fromButtonDidTapped(_ sender: RoundButton) {
        sender.tapAnimation {
            
        }
    }
    
    var totalCost : Double = 0.0 //cost not including delivery and tax
    let headerTitles = ["Your Order", "Other Costs"]
    let data1 = ["Delivery Fee", "Tax", "Tips","Total"]
    var tax : Double = 0.0
    var tips : Double = 0.0
    var deliveryFee : Double = 0.0
    var driverEarned : Double = 0.0
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowCount = 0
        if section == 0 {
            rowCount =  ReceiptModel.shared.numberOfItems()
        }
        if section == 1 {
            rowCount = 4
        }
        return rowCount
    }
    
    @IBAction func deliveryToButtonPressed(_ sender: RoundButton) {
        sender.tapAnimation {
            let vc = self.storyboard?.instantiateViewController(identifier: "DeliveryAddressViewController") as! DeliveryAddressViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func completeOrderButtonDidTapped(_ sender: RoundButton) {
        sender.tapAnimation {
            self.completeOrder()
        }
    }
    
    func completeOrder() {
        for item in ReceiptModel.shared.list {
            if (ReceiptModel.shared.farmIDToCost[item.farmID] != nil) {
                ReceiptModel.shared.farmIDToCost[item.farmID]! += item.price
            } else {
                ReceiptModel.shared.farmIDToCost[item.farmID] = item.price
            }
        }
        print(ReceiptModel.shared.farmIDToCost)
        
        // create order struct
        let market: String = ReceiptModel.shared.market?.marketID ?? ""
        var total_num: Int = 0
        var total_cost: Double = 0.0 // ReceiptModel.shared.totalCost
        var order: [[String: Any]] = [[:]]
        // var shopping_list: [[String: Any]] = [[:]]
        var pair: [String: Any] = [:]
        
        print("here", market, total_cost)
        
        var farm_total_cost: [[String: Any]] = [[:]]

        for item in ReceiptModel.shared.list {
            // create order
            var found: Bool = false
            var new_shopping_list: [[String: Any]] = [[:]]
            pair = ["produce_name": item.produceName, "num": item.num, "unit_price": item.unitPrice, "image_url": item.imageUrl]
            for idx in order.indices {
                if order[idx]["farm"] != nil {
                    if order[idx]["farm"] as! String == item.farmID {
                        new_shopping_list = order[idx]["shopping_list"] as! [[String : Any]]
                        order.remove(at: idx)
                        found = true
                        break
                    }
                }
            }
            
            if !found {
                order.append(["farm": item.farmID, "shopping_list": [pair]])
            } else {
                new_shopping_list.append(pair)
                order.append(["farm": item.farmID, "shopping_list": new_shopping_list])
            }
            
            found = false
            new_shopping_list = [[:]]
            
            
            
            // create farm_total_cost
            var existed_cost: Double = 0.0
            for idx in farm_total_cost.indices {
                if farm_total_cost[idx]["farm"] != nil {
                    if farm_total_cost[idx]["farm"] as! String == item.farmID {
                        existed_cost = farm_total_cost[idx]["cost"] as! Double
                        farm_total_cost.remove(at: idx)
                        break
                    }
                }
            }
            farm_total_cost.append(["farm": item.farmID, "cost": item.price + existed_cost])
            
            
            // update total_num
            total_num += item.num
        }
        
        farm_total_cost.remove(at: 0)
        order.remove(at: 0)
        print("farm order: ", order)
        
        // get current time
        let order_date = Date()
        // dump(order_date)
        
        // calculate money detials and driver earned
        for cost in farm_total_cost {
            total_cost += cost["cost"] as! Double
        }
        deliveryFee = Double(round(100 * 0.25 * total_cost)/100)
        tips = Double(round(100 * 0.15 * total_cost)/100)
        tax = Double(round(100 * 0.07 * total_cost)/100)
        driverEarned = tips + Double(round(100 * 0.5 * deliveryFee)/100)
        total_cost += Double(round(100 * (deliveryFee + tips + tax))/100)
        
        hud.show(in: self.view)
        
        // add to Firestore db
        DatabaseManager.shared.createMarketOrder(market_id: market, total_num: total_num, total_cost: total_cost, orderFromMarket: order, farm_total_cost: farm_total_cost, order_date: order_date, phone_num: phone_num, driver_earned: driverEarned) { [weak self] (orderId) in
            print("On completion: order created.")
            // Wait for payment updates
            DatabaseManager.shared.listenToPaymentUpdates(orderId: orderId) { [weak self] (paymentId, paymentStatus, clientSecret, errorMsg) in
                guard let strongSelf = self else {
                    return
                }
                if let errorMsg = errorMsg {
                    print(errorMsg)
                    strongSelf.handlePaymentFailed()
                    return
                }
                guard let paymentId = paymentId, let paymentStatus = paymentStatus, let clientSecret = clientSecret else {
                    return
                }
                switch paymentStatus {
                case "succeeded":
                    strongSelf.handlePaymentSucceeded()
                case "requires_confirmation":
                    print("Creating payment")
                case "requires_action":
                    print("Payment requires additional action")
                    // Display authentication
                    let paymentHandler = STPPaymentHandler.shared()
                    paymentHandler.handleNextAction(forPayment: clientSecret, with: strongSelf, returnURL: nil) { (status, paymentIntent, error) in
                        if let error = error {
                            print("Error when handleNextAction: \(error)")
                            return
                        }
                        guard let paymentIntent = paymentIntent else {
                            print("Error in payment intent")
                            return
                        }
                        var statusString: String = ""
                        switch paymentIntent.status {
                        case .succeeded:
                            statusString = "succeeded"
                            strongSelf.handlePaymentSucceeded()
                        case .requiresAction:
                            statusString = "requires_action"
                            strongSelf.handlePaymentFailed()
                        case .canceled:
                            statusString = "canceled"
                            strongSelf.handlePaymentFailed()
                        case .requiresPaymentMethod:
                            statusString = "requires_payment_method"
                            strongSelf.handlePaymentFailed()
                        case .requiresConfirmation:
                            statusString = "requires_confirmation"
                            strongSelf.handlePaymentProcessing()
                        case .requiresCapture:
                            statusString = "requires_capture"
                            strongSelf.handlePaymentProcessing()
                        case .processing:
                            statusString = "processing"
                            strongSelf.handlePaymentProcessing()
                        default:
                            print("Unknown payment intent status: \(paymentIntent.status)")
                        }
                        // Update payment intent in database
                        DatabaseManager.shared.updatePaymentStatus(id: paymentId, status: statusString)
                    }
                default:
                    print("Other payment status")
                    // Error
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as! ReceiptTableViewCell
        if indexPath.section == 0 {
            if let item = ReceiptModel.shared.getBoughtItem(at: indexPath.row) {
                cell.produceLabel?.text = item.produceName
                cell.costLabel?.text = String(format: "$%.2f", item.price)
            }
        } else {
            let data2 = [ReceiptModel.shared.totalCost * 0.25, ReceiptModel.shared.totalCost * 0.07, ReceiptModel.shared.totalCost * 0.15, ReceiptModel.shared.totalCost * 1.47]
            cell.produceLabel?.text = data1[indexPath.row]
            cell.costLabel?.text = String(format: "$%.2f", data2[indexPath.row])
        }
        return cell;
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < headerTitles.count {
            return headerTitles[section]
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            ReceiptModel.shared.totalCost -= ReceiptModel.shared.list[indexPath.row].price
            ReceiptModel.shared.list.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    /// Inform user payment succeeded and redirect to next screen
    private func handlePaymentSucceeded() {
        print("Payment succeeded")
        hud.dismiss()
        ReceiptModel.shared.list.removeAll()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let marketVC = storyboard.instantiateViewController(identifier: "MarketsCollectionViewController")
        show(marketVC , sender: self)
    }
    
    /// Inform user payment failed
    private func handlePaymentFailed() {
        print("Payment failed")
        hud.dismiss()
    }
    
    /// Inform user payment is processing
    private func handlePaymentProcessing() {
        print("Payment is processing")
    }
}

extension ReceiptTableViewController: STPAuthenticationContext {
    
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }
    
}
