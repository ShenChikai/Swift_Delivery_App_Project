//
//  ReceiptModel.swift
//  Harvest
//
//  Created by bytedance on 2021/2/11.
//

import Foundation
import UIKit

class ReceiptModel {
    
    var list: [BoughtItem] = []
    public static var shared = ReceiptModel()
    var totalCost: Double = 0.0
    var market: Market?
    var date = Date()
    var numOfItems: Int = 0
    var farmIDToCost = [String: Double]()
    init() {}
    
    init(market: Market){
        self.market = market
    }
    
    init(market: Market, date: Date, total: Double, numOfItems: Int){
        self.market = market
        self.date = date
        self.totalCost = total
        self.numOfItems = numOfItems
    }
    
    func numberOfItems() -> Int {
        return list.count
    }
    
    func insert(item : BoughtItem) {
        list.append(item)
    }
    
    func getBoughtItem(at Index: Int) -> BoughtItem? {
        return list[Index]
    }
    
    func getBoughtDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let completeDate = dateFormatter.string(from: date)
        return String(completeDate.dropLast(6)) // drop year representation
    }
    
}
