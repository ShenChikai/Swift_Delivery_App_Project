//
//  SettingsTableViewController.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/3/30.
//

import UIKit
import FirebaseAuth

class SettingsTableViewController: UITableViewController {
    
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

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.tableFooterView = UIView()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.cellForRow(at: indexPath)?.tapAnimation {
            switch indexPath.row {
            case 1:
                let vc = self.storyboard?.instantiateViewController(identifier: "PaymentDetailsTableViewController") as! PaymentDetailsTableViewController
                self.navigationController?.pushViewController(vc, animated: true)
            case 9:
                self.signOut()
            default:
                print("Not active")
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            let vc = self.storyboard?.instantiateViewController(identifier: "HomeNavigationController") as! UINavigationController
            self.navigationController?.showDetailViewController(vc, sender: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

}
