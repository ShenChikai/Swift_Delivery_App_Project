//
//  ProducesDisplayAllViewController.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/3/3.
//  Editied by Zixuan Li on 2021/3/8
//

import UIKit

class ProducesDisplayAllViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var categories: [String] = ["Popular Items", "In Season", "Leafy Greens"]

    var allProduces = [String: [Produce]]()

    
    // testing prepare
    var farmID = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

}

extension ProducesDisplayAllViewController: UITableViewDelegate {
    
}

extension ProducesDisplayAllViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as! ProducesTableViewCell
        cell.farmID = farmID
        cell.categoryLabel.text = categories[indexPath.row]
        cell.produces = allProduces[categories[indexPath.row]] ?? []
        cell.width = view.frame.size.width
        cell.collectionView.reloadData()
        cell.produceAllVc = self
        return cell
    }
    
}
