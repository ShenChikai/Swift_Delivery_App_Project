//
//  PaymentDetailsTableViewController.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/3/30.
//

import UIKit
import JGProgressHUD

class PaymentDetailsTableViewController: UITableViewController {
    
    private var paymentMethods: [PaymentMethod] = []
    
    private let hud = JGProgressHUD()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        hud.textLabel.text = "Loading"

        DatabaseManager.shared.listenToAllPaymentMethods { [weak self] (paymentMethods) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.paymentMethods = paymentMethods
            DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func setupNavigationBar() {
        // Adjust font
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Roboto-Medium", size: 18)!]
    }
    
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func defaultCheckboxPressed(_ sender: UIButton) {
        let paymentMethod = paymentMethods[sender.tag]
        if paymentMethod.isDefault {
            return
        }
        hud.show(in: self.view)
        DatabaseManager.shared.setDefaultPaymentMethod(as: paymentMethod) {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.hud.dismiss()
            }
        }
    }
    
    @IBAction func addPaymentButtonPressed(_ sender: UIButton) {
        sender.tapAnimation {
            let vc = self.storyboard?.instantiateViewController(identifier: "AddPaymentViewController") as! AddPaymentViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paymentMethods.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath)
        guard indexPath.row < paymentMethods.count else {
            return cell
        }
        let paymentMethod = paymentMethods[indexPath.row]
        cell.textLabel?.text = "**** \(paymentMethod.last4)"
        cell.imageView?.image = paymentMethod.brandImage
        
        let rightButton = UIButton()
        rightButton.tag = indexPath.row
        rightButton.setImage(UIImage(systemName: paymentMethod.isDefault ? "checkmark.circle.fill" : "circle")?.withRenderingMode(.alwaysTemplate), for: .normal)
        rightButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        rightButton.contentMode = .scaleAspectFit
        rightButton.addTarget(self, action: #selector(defaultCheckboxPressed(_ :)), for: .touchUpInside)
        rightButton.tintColor = UIColor(named: "GreenTheme") ?? .green
        cell.accessoryView = rightButton as UIView
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Remove the payment method from database
            hud.show(in: self.view)
            DatabaseManager.shared.removePaymentMethod(paymentMethod: paymentMethods[indexPath.row]) { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                DispatchQueue.main.async {
                    strongSelf.tableView.reloadData()
                    strongSelf.hud.dismiss()
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
