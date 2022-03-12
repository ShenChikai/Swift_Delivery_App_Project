//
//  SettingsViewController.swift
//  Harvest
//
//  Created by Zixuan Li on 2021/2/13.
//
//  WARNING: this class is not in use.

import Foundation
import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        // load user name
        DatabaseManager.shared.retrieveUserName { [weak self] (firstName, lastName) in
            guard let strongSelf = self else {
                return
            }
            let userName = firstName + " " + lastName
            DispatchQueue.main.async{
                strongSelf.userNameLabel.text = userName
            }
            
        }
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor)
        ])
    }
    
    var options = [
        Links(item: "Account Details", segueIdent: "account"),
        Links(item:"Payment", segueIdent: "payment"),
        Links(item: "Help", segueIdent: "help"),
        Links(item: "Notifications", segueIdent: "notifications"),
        Links(item: "Drive for us", segueIdent: "driver"),
        Links(item: "Promos", segueIdent: "promo"),
        Links(item: "Terms of Service", segueIdent: "terms"),
        Links(item: "Privacy policy", segueIdent: "privacy"),
        Links(item: "About", segueIdent: "about")
    ]
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsTableViewCell
        cell.item.text = options[indexPath.item].item
        cell.Button.segueIdent = options[indexPath.item].segueIdent
        cell.Button.addTarget(self, action: #selector(self.segueTrigger(_ :)), for: .touchUpInside)
        return cell
    }
    
    // offset each row height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    @IBAction func buttonBackPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // set segue ident for button
    @objc func segueTrigger(_ sender: LinkButton) {
        self.performSegue(withIdentifier: sender.segueIdent, sender: self)
    }
}
