//
//  DatabaseManager.swift
//  Harvest-Business
//
//  Created by Zixuan Li on 2021/3/17.
//

import Foundation
import Firebase
import CoreLocation

/// Singleton class for all operations on Firebase Firestore
final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Firestore.firestore()
    
    // MARK: - Sign in/Sign up
    /// Check if driver/farmer with the same email exists in database
    public func userExists(with email: String, type: String, completion: @escaping ((Bool) -> Void)) {
        database.collection(type).whereField("email", isEqualTo: email).getDocuments { (querySnapShot, error) in
            if let error = error {
                print("Error checking \(type) exists: \(error)")
                completion(false)
                return
            }
            if (querySnapShot?.isEmpty)! {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Insert new farmer into database
    public func insertFarmer(with farmer: Farmer) {
        // Use currentUser.uid as document id
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("farms").document(uid).setData(farmer.dictionary, merge: true) { (error) in
            if let error = error {
                print("Error inserting farmer: \(error)")
                return
            }
            print("Added farmer: \(farmer.dictionary)")
        }
    }
    
    /// Insert new driver into database
    public func insertDriver(with driver: Driver) {
        // Use currentUser.uid as document id
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("drivers").document(uid).setData(driver.dictionary, merge: true) { (error) in
            if let error = error {
                print("Error inserting driver: \(error)")
                return
            }
            print("Added driver: \(driver.dictionary)")
        }
    }
    
    /// retrieve user name; can be modified later to retrieve all info
    public func retrieveUserName(type: String, completion: @escaping ((String, String) -> Void)){
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        
        let userRef = database.collection(type).document(uid)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists, let dictionary = document.data() {
                let firstName = dictionary["first_name"] as! String
                let lastName = dictionary["last_name"] as! String
                completion(firstName, lastName)
            } else {
                print("Error retrieving user name \(userRef): Document does not exist or error during reading")
            }
        }
    }
    

    // MARK: - Farmer side
    /// retrieve available produces with provided category and farmID
    public func retrieveProduces(with category: String, farmID: String, completion: @escaping ((Produce) -> Void)){
        database.collection("farms/" + farmID + "/products").whereField("category", arrayContains: category).getDocuments() { (document, error) in
              if let error = error {
                  print("Error retrieving produces for farm: \(error)")
              } else{
                
                print("retrieving current category \(category)")
                
                  for document in document!.documents {
                    let dictionary = document.data()
                    if dictionary["inventory"] as! Int > 0{
                        
                        let produce = Produce(image: UIImage(named: "onion"), name: dictionary["name"] as! String, unitPrice: dictionary["unit_price"] as! Double, unit: dictionary["unit"] as! Int, category: category, description: dictionary["description"] as! String, inventory: dictionary["inventory"] as! Int, image_url: dictionary["picture_url"] as! String)
                        
                        completion(produce)
                    }
                  }
              }
        }
    }
    
    // MARK: - Driver side
    
    /// retrieve markets and return as sorted by distance
    public func retrieveSortedMarkets(_ currentLoc: CLLocation, completion: @escaping (([Market]) -> Void)) {
        retrieveMarketsHelper(currentLoc) { (markets) in
            if (markets.count > 0) {
                print("retrieved \(markets.count) open markets")
                
                var sortedMarkets = markets
                sortedMarkets.sort { (mkt1, mkt2) -> Bool in
                    return mkt1.distance < mkt2.distance
                }
                completion(sortedMarkets)
            }
        }
    }
    
    /// helper to retrieve all open markets (unsorted)
    private func retrieveMarketsHelper(_ currentLoc: CLLocation,completion: @escaping (([Market]) -> Void))  {
        
        // retrieve unvisited open market
        database.collection("markets").getDocuments { (document, error) in
            if error != nil {
                print("Error retrieving open markets")
            }
            else{
                // if no more unvisited markets
                if(document!.documents.isEmpty){
                    print("no more unvisited markets")
                    return
                }
                
                // get current hour/day of week
                let currentDayOfWeek = String(Date().dayOfTheWeek()!)
                let currentHour = Calendar.current.component(.hour, from: Date())
                
                var markets = [Market]()
                
                for document in document!.documents {
                    
                    let dictionary = document.data()
                    
                    // make sure the market is open
                    let dayOpen = dictionary["day_open"] as! [String]
                    if dayOpen.contains(currentDayOfWeek) {
                        let timeOpen = Int((dictionary["time_open"] as! String).prefix(2))!
                        let timeClose = Int((dictionary["time_close"] as! String).prefix(2))!
                        
                        if(timeOpen <= currentHour && timeClose > currentHour){
                            let addressDict = dictionary["address"] as! [String : Any]
                            let market = Market(title: dictionary["name"] as! String, address: addressDict["title"] as! String, lat: addressDict["lat"] as! Double, lon: addressDict["lon"] as! Double, distance: 0, marketID: dictionary["marketID"] as! String)
                            market.distance = CLLocation(latitude: market.lat, longitude: market.lon).distance(from: currentLoc)
                            
                            print("retrieved market \(market.title)")
                            
                            markets.append(market)
                        }
                    } // end of check day_open
                } // end of loop documents
                completion(markets)
            }
        }
        
    }

    /// retrieve available orders for certain market (by default: nearest)
    public func retrieveOrders(_ currentLoc: CLLocation, marketIdx: Int, _ markets: [Market], completion: @escaping ((Order, DocumentReference) -> Void)) {
        print("now retrieving market idx \(marketIdx)")
        retrieveOrdersHelper(currentLoc, marketIdx, markets, completion: completion)
    }
    
    /// retrieve orders  helper, recursion until find available orders
    private func retrieveOrdersHelper(_ currentLoc: CLLocation, _ marketIdx: Int, _ markets: [Market], completion: @escaping ((Order, DocumentReference) -> Void)) {

        if(marketIdx >= markets.count){
            print("no orders available")
            return
        }
        // only retrieve at most 2 least recent unretrieved order
        self.database.collection("orders").whereField("market", isEqualTo: markets[marketIdx].marketID).whereField("delivery_status", isEqualTo: "created").limit(to: 2).getDocuments { (document, error) in
            if let error = error {
                print("Error retrieving nearest orders for driver: \(error)")
            } else {
                
                for documentOrder in document!.documents {
                    let dictionaryOrder = documentOrder.data()
                    
                    // get customer
                    self.database.collection("customers").document(documentOrder["customer"] as! String).getDocument { (document, error) in
                        if let document = document, document.exists {
                            let dictionaryCustomer = document.data()!
                            let dictionaryActiveAddress = dictionaryCustomer["active_address"] as! [String: Any]
                            
                            // convert timestamp to NSdate
                            guard let stamp = dictionaryOrder["order_date"] as? Timestamp else {
                                print("Error converting timestamp to NSDate")
                                return
                            }
                            let date = stamp.dateValue()
                            let customerId = document.documentID
                            let customerAddressTitle = dictionaryActiveAddress["title"] as! String
                            let customerAddressSubtitle = dictionaryActiveAddress["subtitle"] as! String
                            let customerLon = dictionaryActiveAddress["lon"] as! Double
                            let customerLat = dictionaryActiveAddress["lat"] as! Double
                            let customer = Customer(firstName: dictionaryCustomer["first_name"] as! String, lastName: dictionaryCustomer["last_name"] as! String, phoneNum: dictionaryCustomer["phone_num"] as! String, imageUrl: dictionaryCustomer["image_url"] as! String)
                            let numOfItems = dictionaryOrder["total_num"] as! Int
                            let farmIDToOrder = dictionaryOrder["order"] as! [[String: Any]]
                            let totalEarned = dictionaryOrder["driver_earned"] as? Double ?? 7.00
                            let pickupStatus = dictionaryOrder["pickup_status"] as? Bool ?? false
                            
                            let order = Order(id: documentOrder.documentID, date: date, customerId: customerId, customerAddressTitle: customerAddressTitle, customerAddressSubtitle: customerAddressSubtitle, customer: customer, customerLon: customerLon, customerLat: customerLat, marketId: markets[marketIdx].marketID, marketName: markets[marketIdx].title, marketAddressTitle: markets[marketIdx].address, totalEarned: totalEarned, numOfItems: numOfItems, farmIDToOrder: farmIDToOrder, pickupStatus: pickupStatus)
                            
                            // update delivery status to retrieved
                            documentOrder.reference.updateData(["delivery_status": "retrieved"])
                            
                            completion(order, documentOrder.reference)
                        
                        } else {
                            print("Error retrieving specified customer for current order")
                        }
                    }

                } // end of loop documents
                if(document!.documents.isEmpty){
                    self.retrieveOrders(currentLoc, marketIdx: marketIdx + 1, markets, completion: completion)
                }
            }
        }
    }
    
    /// update order delivery status to specified status
    public func updateOrderStatus(status: String, orderRef: DocumentReference) {
        orderRef.getDocument { (document, error) in
            if let document = document, document.exists {
                document.reference.updateData(["delivery_status": status])
            } else {
                print("Error updating delivery status to \(status)")
            }
        }
    }
    
    /// Update the pickup status of 'order'
    public func updatePickupStatus(orderId: String, deliverySessionId: String, status: Bool, completion: @escaping () -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("drivers").document(uid)
            .collection("delivery_sessions").document(deliverySessionId)
            .collection("orders").document(orderId)
            .updateData(["pickup_status": status]) { (error) in
                if let error = error {
                    print("DatabaseManager - updatePickupStatus: \(error)")
                    return
                }
                completion()
            }
    }
    
    // MARK: - driver session (active orders) related
    
    /// add new delivery session
    public func addDeliverySession(marketID: String, order1ID: String?, order2ID: String?) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        
        var orderIDs = [String]()
        if order1ID != nil {
            orderIDs.append(order1ID!)
        }
        if order2ID != nil {
            orderIDs.append(order2ID!)
        }
        print("orderID is \(orderIDs.count)")
        
        let data = [
            "market_id": marketID,
            "order_ids": orderIDs,
            "step": 0
        ] as [String : Any]
        // Use batched writes
        let batch = database.batch()
        // Set delivery session and update current_session
        let driverRef = database.collection("drivers").document(uid)
        let sessionRef = driverRef.collection("delivery_sessions").document()
        batch.setData(data, forDocument: sessionRef)
        batch.updateData(["current_session": sessionRef.documentID], forDocument: driverRef)
        // Update order 1
        if order1ID != nil {
            let orderRef = database.collection("orders").document(order1ID!)
            batch.updateData([
                "driver_id": uid,
                "delivery_session_id": sessionRef.documentID
            ], forDocument: orderRef)
        }
        // Update order 2
        if order2ID != nil {
            let orderRef = database.collection("orders").document(order2ID!)
            batch.updateData([
                "driver_id": uid,
                "delivery_session_id": sessionRef.documentID
            ], forDocument: orderRef)
        }
        batch.commit { (error) in
            if let error = error {
                print("Error adding new delivery session: \(error)")
                return
            }
            print("New delivery session \(sessionRef.documentID) added")
        }
    }
    
    /// add order to driver's active order list
    // NOTE: NOT TEST
    private func addActiveOrders(orderID: String) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        let docRef = database.collection("drivers").document(uid)
        docRef.getDocument { (document, error) in
            if error != nil {
                print("Error retrieving sessionID when adding active order")
                return
            } else {
                let sessionID = document!.data()!["current_session"] as! String
                
                docRef.collection("delivery_sessions").document(sessionID).updateData(["active_orders": FieldValue.arrayUnion([orderID])]) { (error) in
                    if error != nil {
                        print("Error saving to active orders")
                        return
                    }
                }
            }
        }
    }
    
    /// remove order from driver's active order list
    // NOTE: NOT TEST
    private func removeActiveOrders(orderID: String) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        
        let docRef = database.collection("drivers").document(uid)
        let sessionID = docRef.value(forKey: "current_session") as! String
        
        docRef.collection("delivery_sessions").document(sessionID).updateData(["active_orders": FieldValue.arrayRemove([orderID])]) { (error) in
            if error != nil {
                print("Error saving to active orders")
                return
            }
        }
    }
    
    /// retrieve all active orders
    public func retrieveActiveOrders(completion: @escaping ((Order) -> Void)) {
        guard let user = Auth.auth().currentUser else {
                    print("Not signed in")
                    return
                }
        let uid = user.uid
        
        let docRef = database.collection("drivers").document(uid)
        retrieveCurrentSessionId(for: uid) { (sessionID) in
            guard let sessionID = sessionID else {
                return
            }
            docRef.collection("delivery_sessions").document(sessionID).collection("orders").getDocuments { (document, error) in
                if error != nil {
                    print("Error retrieving orders to display")
                    return
                } else {
                    
                    for documentOrder in document!.documents {
                        let dictionaryOrder = documentOrder.data()
                        
                        let customer = Customer(firstName: dictionaryOrder["customer_first_name"] as! String, lastName: dictionaryOrder["customer_last_name"] as! String, phoneNum: dictionaryOrder["customer_phone_num"] as! String, imageUrl: dictionaryOrder["customer_image_url"] as! String)
                        
                        let orderOuterDict = dictionaryOrder["order"] as! [String: Any]
                        let customerId = orderOuterDict["customer"] as! String
                        let customerAddressDict = dictionaryOrder["customer_active_address"] as! [String: Any]
                        let customerAddressTitle = customerAddressDict["title"] as! String
                        let customerAddressSubtitle = customerAddressDict["subtitle"] as! String
                        let customerLon = customerAddressDict["lon"] as! Double
                        let customerLat = customerAddressDict["lat"] as! Double
                        let numOfItems = orderOuterDict["total_num"] as! Int
                        let farmIDToOrder = orderOuterDict["order"] as! [[String: Any]]
                        let totalEarned = orderOuterDict["driver_earned"] as? Double ?? 7.00
                        let pickupStatus = dictionaryOrder["pickup_status"] as? Bool ?? false
                        
                        // convert timestamp to NSdate
                        guard let stamp = orderOuterDict["order_date"] as? Timestamp else {
                            print("Error converting timestamp to NSDate")
                            return
                        }
                        let date = stamp.dateValue()
                        
                        // get market
                        self.database.collection("markets").document(orderOuterDict["market"] as! String).getDocument { (document, error) in
                            if let document = document, document.exists {
                                let dictionaryMarket = document.data()!
                                
                                let addressDict = dictionaryMarket["address"] as! [String : Any]
                                let marketId = dictionaryMarket["marketID"] as! String
                                let marketName = dictionaryMarket["name"] as! String
                                let marketAddressTitle = addressDict["title"] as! String
                           
                                let order = Order(id: documentOrder.documentID, date: date, customerId: customerId, customerAddressTitle: customerAddressTitle, customerAddressSubtitle: customerAddressSubtitle, customer: customer, customerLon: customerLon, customerLat: customerLat, marketId: marketId, marketName: marketName, marketAddressTitle: marketAddressTitle, totalEarned: totalEarned, numOfItems: numOfItems, farmIDToOrder: farmIDToOrder, pickupStatus: pickupStatus)
                                
                                completion(order)
                            } else {
                                print("Error retrieving market for current active order")
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func farmIDtoName(_ farmID: String, completion: @escaping (String) -> Void) {
        database.collection("farms").document(farmID).getDocument { (document, error) in
            if let error = error {
                print("Error getting farm name from farmID \(error)")
                return
            } else {
                print("translating farmID: " + farmID)
                completion(document!.data()!["name"] as! String)
            }
        }
    }
    
    // MARK: - Driver Delivery
    
    /// Retrieve the current session of the driver
    /// When completion is called, all orders within the current delivery session will be added to DeliverySession
    public func retrieveCurrentSession(completion: @escaping (DeliverySession?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        let docRef = database.collection("drivers").document(uid)
        // Get current session id
        retrieveCurrentSessionId(for: uid) { (currentSessionId) in
            guard let currentSessionId = currentSessionId else {
                completion(nil)
                return
            }
            // Use listener to listen until all fields are populated by cloud functions
            var deliverySessionListner: ListenerRegistration?
            deliverySessionListner = docRef.collection("delivery_sessions").document(currentSessionId).addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("DatabaseManager - retrieveCurrentSession: snapshot listener error \(error)")
                    return
                }
                guard let document = snapshot, document.exists else {
                    print("DatabaseManager - retrieveCurrentSession: error feteching document")
                    return
                }
                guard let step = document.get("step") as? Int, let orderIds = document.get("order_ids") as? [String], let marketId = document.get("market_id") as? String, let marketName = document.get("market_name") as? String, let marketAddress = document.get("market_address") as? [String: Any], let marketLat = marketAddress["lat"] as? Double, let marketLon = marketAddress["lon"] as? Double, let marketAddressTitle = marketAddress["title"] as? String else {
                    print("DatabaseManager - retrieveCurrentSession: missing required fields")
                    return
                }
                // Listen to all orders in the session
                var ordersListener: ListenerRegistration?
                ordersListener = docRef.collection("delivery_sessions").document(currentSessionId)
                    .collection("orders").order(by: "index").addSnapshotListener { (snapshot, error) in
                        if let error = error {
                            print("DatabaseManager - retrieveCurrentSession: error gettting orders: \(error)")
                            return
                        }
                        guard snapshot!.documents.count == orderIds.count else {
                            return
                        }
                        var orders: [Order] = []
                        // Add each order to DeliverySession
                        for document in snapshot!.documents {
                            let order = document.data()["order"] as! [String: Any]
                            let customerActiveAddress = document.data()["customer_active_address"] as! [String: Any]
                            let lon = customerActiveAddress["lon"] as! Double
                            let lat = customerActiveAddress["lat"] as! Double
                            let customerAddressTitle = customerActiveAddress["title"] as! String
                            let customerAddressSubtitle = customerActiveAddress["subtitle"] as! String
                            let customerId = order["customer"] as! String
                            let date = (order["order_date"] as! Timestamp).dateValue()
                            let firstName = document.data()["customer_first_name"] as! String
                            let lastName = document.data()["customer_last_name"] as! String
                            let phoneNum = document.data()["customer_phone_num"] as! String
                            let imageUrl = document.data()["customer_image_url"] as! String
                            let customer = Customer(firstName: firstName, lastName: lastName, phoneNum: phoneNum, imageUrl: imageUrl)
                            let numOfItems = order["total_num"] as! Int
                            let farmIDToOrder = order["order"] as! [[String: Any]]
                            let totalEarned = order["driver_earned"] as? Double ?? 7.00
                            let pickupStatus = document.data()["pickup_status"] as? Bool ?? false
                            orders.append(Order(id: document.documentID, date: date, customerId: customerId, customerAddressTitle: customerAddressTitle, customerAddressSubtitle: customerAddressSubtitle, customer: customer, customerLon: lon, customerLat: lat, marketId: marketId, marketName: marketName, marketAddressTitle: marketAddressTitle, totalEarned: totalEarned, numOfItems: numOfItems, farmIDToOrder: farmIDToOrder, pickupStatus: pickupStatus))
                        }
                        let deliverySession = DeliverySession(id: currentSessionId, orders: orders, step: step, marketLat: marketLat, marketLon: marketLon, marketAddressTitle: marketAddressTitle, marketName: marketName)
                        print("DatabaseManager - retrieveCurrentSession: success")
                        completion(deliverySession)
                        // Detach listeners upon success
                        deliverySessionListner?.remove()
                        ordersListener?.remove()
                    }
            }
        }
    }
    
    /// Update the real-time location of driver and increment step or reset current order if needed
    public func updateDriverLocation(lat: Double, lon: Double) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("drivers").document(uid).setData(["lat": lat, "lon": lon], merge: true) { (error) in
            if let error = error {
                print("DatabaseManager - updateDriverLocation: \(error)")
                return
            }
            print("DatabaseManager - updateDriverLocation succeeded")
        }
    }
    
    /// Clear the 'current_session' field of driver
    public func resetCurrentSession() {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("drivers").document(uid)
            .updateData(["current_session": FieldValue.delete()]) { (error) in
                if let error = error {
                    print("Error in DatabaseManager - resetCurrentSession: \(error)")
                    return
                }
                print("DatabaseManager - resetCurrentSession succeeded")
            }
    }
    
    /// Increment the 'step' field  of session with 'id' by 1
    public func incrementCurrentSessionStep(id currentSessionId: String, completion: @escaping () -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("drivers").document(uid)
            .collection("delivery_sessions").document(currentSessionId)
            .updateData(["step": FieldValue.increment(Int64(1))]) { (error) in
                if let error = error {
                    print("Error in DatabaseManager - incrementCurrentSessionStep: \(error)")
                    return
                }
                print("DatabaseManager - incrementCurrentSessionStep succeeded")
                completion()
            }
    }
    
    /// Retrieve current session id for driver with 'uid'
    private func retrieveCurrentSessionId(for uid: String, completion: @escaping (String?) -> Void) {
        let docRef = database.collection("drivers").document(uid)
        docRef.getDocument { (document, error) in
            guard let document = document, document.exists else {
                print("Error retrieving current session field for \(uid)")
                return
            }
            if let currentSessionId = document.get("current_session") as? String {
                completion(currentSessionId)
                return
            }
            completion(nil)
        }
    }

    // MARK: - Address
    
    
    /// Insert an address for current user
    public func insertAddress(addressLine: String, city: String, postalCode: Int) {
        // Use currentUser.uid as document id
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        let dataDict: [String : Any] = [
            "address_line": addressLine,
            "city": city,
            "postal_code": postalCode
        ]
        database.collection("customers").document(uid).updateData([
            "addresses": FieldValue.arrayUnion([dataDict])
        ]) { (error) in
            if let error = error {
                print("Error inserting address: \(error)")
                return
            }
            print("Added address.")
        }
    }
    
    /// insert an address for this customer
    public func insertAddress2(title: String, subtitle: String, lat: Double, lon: Double) {
        print("Attempt to insert address in insert2.")
        // Use currentUser.uid as document id
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        print("uid acquired: ", uid)
        // title = address, subtitle = thorough address
        let dataDict: [String : Any] = [
            "title": title,
            "subtitle": subtitle,
            "lat": lat,
            "lon": lon
        ]
        print("adding: ", dataDict)
        database.collection("customers").document(uid).updateData([
            "addresses": FieldValue.arrayUnion([dataDict])
        ]) { (error) in
            if let error = error {
                print("Error inserting address: \(error)")
                return
            }
            print("Added address.")
        }
        print("done inserting addr")
    }
    
    /// Retrieve saved addresses for current user
    public func retrieveSavedAddresses(completion: @escaping (([Address]) -> Void)) {
        // Use currentUser.uid as document id
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        
        var savedAddress = [Address]()
        
        let docRef = database.collection("customers").document(uid)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                
                
                if let fetchAddress = document.data()!["addresses"]! as? [[String : Any]] {
                    
                    for addr in fetchAddress {
                        let title = addr["title"] as! String
                        let subtitle = addr["subtitle"] as! String
                        let lat = addr["lat"] as! Double
                        let lon = addr["lon"] as! Double
                        let newAddr = Address(title: title, subtitle: subtitle, lat: lat, lon: lon)
                        savedAddress.append(newAddr)
                        
                    }
                    
                } else {
                    print("Error retrieiving saved addr")
                }
                
                completion(savedAddress)
            } else {
                print("Error retrieving saved addr: Document does not exist")
            }
        }
    }
    
    /// set active address
    public func setActiveAddress(title: String, subtitle: String, lat: Double, lon: Double) {
        print("Attempt to insert address in insert2.")
        // Use currentUser.uid as document id
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        
        let dataDict: [String : Any] = [
            "title": title,
            "subtitle": subtitle,
            "lat": lat,
            "lon": lon
        ]
        
        let docRef = database.collection("customers").document(uid)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                document.reference.updateData(["active_address": dataDict])
            } else {
                print("Error retrieving addr: Document does not exist")
            }
        }
    }
    
    /// retrieve active address
    public func retrieveActiveAddress(completion: @escaping ((String, String, Double, Double) -> Void)){
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        
        let userRef = database.collection("customers").document(uid)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists, let dictionary = document.data() {
                let address = dictionary["active_address"] as! [String: Any]
                
                let title = address["title"] as! String
                let subtitle = address["subtitle"] as! String
                let lat = address["lat"] as! Double
                let lon = address["lon"] as! Double
                
                completion(title, subtitle, lat, lon)
            } else {
                print("Error retrieving active address \(userRef): Document does not exist or error during reading")
            }
        }
    }
    
    /// active address: get lat and lon
    
    
    
    // MARK: - Payment
    
    /// Inserts a payment method id to current customer
    public func insertPaymentMethod(id: String) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        let dataDict: [String : Any] = [
            "id": id,
        ]
        database.collection("customers").document(uid)
            .collection("payment_methods").addDocument(data: dataDict) { (error) in
                if let error = error {
                    print("Error inserting payment method: \(error)")
                    return
                }
                print("Inserted payment method.")
            }
    }
    
    /// Listen for changes in customer data
    public func listenForCustomerUpdates(completion: @escaping ([String: Any]) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("customers").document(uid).addSnapshotListener { (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            guard let data = document.data() else {
                print("Document data was empty.")
                return
            }
            completion(data)
        }
    }
    
    /// Check if current user has registered a stripe account
    public func stripeAccountExists(completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("farms").document(uid).getDocument { (document, error) in
            if let document = document, document.exists {
                if document.get("stripe_account_id") != nil {
                    completion(true, nil)
                } else {
                    let stripeError = document.get("stripe_onboarding_error") as? String
                    completion(false, stripeError ?? "Onboarding is not done")
                }
            } else {
                print("Error checking stripe account: Document does not exist or error during reading")
            }
        }
    }
}



