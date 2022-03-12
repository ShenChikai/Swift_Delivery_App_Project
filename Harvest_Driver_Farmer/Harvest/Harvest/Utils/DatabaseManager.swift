//
//  DatabaseManager.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/3/1.
//

import Foundation
import Firebase

/// Singleton class for all operations on Firebase Firestore
final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Firestore.firestore()
    
    // MARK: - Admin
    /// Mass Insert for produce
    public func massInsertProduce(farm_id: String, name: String, categoryArr: [String], unit_price: Double){
        // Admin account use only
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        
        if uid == "CiUt1UfCocQ8Zvx1gWwVHWGk0502" {
        
            var produceDict: [String: Any] = [:]
            produceDict["category"] = categoryArr
            produceDict["description"] = "100% Organic."
            produceDict["inventory"] = 999
            produceDict["name"] = name.replacingOccurrences(of: "_", with: " ")
            produceDict["picture_url"] = "image/produce/" + name + ".jpg"
            produceDict["unit"] = 0
            produceDict["unit_price"] = Double(round(100*unit_price)/100)
            
            database.collection("farms").document(farm_id).collection("products").addDocument(data: produceDict) { (error) in
                if let error = error {
                    print("Error mass inserting produce: \(error)")
                    return
                }
                print("Added customer: \(name)")
            }
                
        } else {
            print("Failed Insert: This is not a admin account.")
        }

    }
    
    // MARK: - Customer
    
    /// Check if customer with the same email exists in database
    public func customerExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        database.collection("customers").whereField("email", isEqualTo: email).getDocuments { (querySnapShot, error) in
            if let error = error {
                print("Error checking customer exists: \(error)")
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
    
    /// Insert new customer into database
    public func insertCustomer(with customer: Customer) {
        // Use currentUser.uid as document id
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("customers").document(uid).setData(customer.dictionary, merge: true) { (error) in
            if let error = error {
                print("Error inserting customer: \(error)")
                return
            }
            print("Added customer: \(customer.dictionary)")
        }
    }
    
    /// retrieve user name; can be modified later to retrieve all info
    public func retrieveUserName(completion: @escaping ((String, String) -> Void)){
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        
        let userRef = database.collection("customers").document(uid)
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
    
    /// retrieve user name; can be modified later to retrieve all info
    public func retrieveUserPhone(completion: @escaping ((String) -> Void)){
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        
        let userRef = database.collection("customers").document(uid)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists, let dictionary = document.data() {
                let phone_num = dictionary["phone_num"] as! String
                completion(phone_num)
            } else {
                print("Error retrieving user phone \(userRef): Document does not exist or error during reading")
            }
        }
    }
    
    /// Retrieve current customer
    public func retrieveCustomer(completion: @escaping (Customer) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        
        let userRef = database.collection("customers").document(uid)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists, let dictionary = document.data() {
                let customer = Customer(dictionary: dictionary)
                completion(customer)
            } else {
                print("Error retrieving user phone \(userRef): Document does not exist or error during reading")
            }
        }
    }
    
    // MARK: - Market
    
    /// Retrieve saved markets for current user
    /// Completion handler will be called for each of the markets
    public func retrieveSavedMarkets(completion: @escaping ((Market) -> Void)) {
        // Use currentUser.uid as document id
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        let docRef = database.collection("customers").document(uid)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let savedMarketRefs = document.get("saved_markets") as? [DocumentReference] {
                    for docRef in savedMarketRefs {
                        self.retrieveSingleMarket(by: docRef, isSaved: true, completion: completion)
                    }
                } else {
                    
                }
            } else {
                print("Error retrieving saved markets: Document does not exist")
            }
        }
    }
    
    /// Retrieve ALL markets for current user
    /// Completion handler will be called for each of the markets
    public func retrieveAllMarkets(completion: @escaping ((Market) -> Void)) {
        // Use currentUser.uid as document id
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        print(uid)
        
        database.collection("markets").getDocuments() { (allMarkets, err) in
            if err != nil{
                print("Error retriving all Markets")
            } else {
                for docRef in allMarkets!.documents {
                    self.retrieveSingleMarket(by: docRef.reference, completion: completion)
                }
            }
        }
    }
    
    /// Add a market to current user's saved markets
    public func addMarketToSaved(market: Market, completion: ((Market, Bool) -> Void)?) {
        guard !market.isSaved, let ref = market.ref else {
            print("Invalid saved status or no ref attached to market")
            return
        }
        // Use currentUser.uid as document id
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("customers").document(uid).updateData([
            "saved_markets": FieldValue.arrayUnion([ref])
        ]) { (error) in
            if let error = error {
                print("Error add saved market: \(error)")
                return
            }
            print("Added saved market.")
            market.invertSavedStatus()
            if let completion = completion {
                completion(market, true)
            }
        }
    }
    
    /// Remove a market from current user's saved markets
    public func removeMarketFromSaved(market: Market, completion: ((Market, Bool) -> Void)?) {
        guard market.isSaved, let ref = market.ref else {
            print("Invalid saved status or no ref attached to market")
            return
        }
        // Use currentUser.uid as document id
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("customers").document(uid).updateData([
            "saved_markets": FieldValue.arrayRemove([ref])
        ]) { (error) in
            if let error = error {
                print("Error removing saved market: \(error)")
                return
            }
            print("Removed saved market.")
            market.invertSavedStatus()
            if let completion = completion {
                completion(market, false)
            }
        }
    }
    
    /// Helper function to retrieve a single market given a reference
    private func retrieveSingleMarket(by docRef: DocumentReference, isSaved: Bool = false, completion: @escaping ((Market) -> Void)) {
        docRef.getDocument { (document, error) in
            if let document = document, document.exists, let dictionary = document.data() {
                let address = dictionary["address"] as! [String: Any]
                let market = Market(title: dictionary["name"] as! String, description: dictionary["description"] as! String, ratings: 5, distance: "3 miles", image_url: dictionary["image_url"] as! String, lat: address["lat"]! as! Double, lon: address["lon"] as! Double, isSaved: isSaved, ref: docRef, marketID: dictionary["marketID"] as! String)
                completion(market)
            } else {
                print("Error retrieving single market \(docRef): Document does not exist or error during reading")
            }
        }
    }
    
    // MARK: - Order
    
    /// retrieve previous orders for current user
    public func retrieveOrders(completion: @escaping ((ReceiptModel) -> Void)) {
        // Use currentUser.uid as document id
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        
        database.collection("orders").whereField("customer", isEqualTo: uid).getDocuments() { (document, error) in
            if let error = error {
                print("Error retrieving previous orders: \(error)")
            } else{
                for document in document!.documents {
                    let dictionary = document.data()
                    
                    // retrieve market with id
                    var market = Market()
                    
                    if let marketStr = dictionary["market"] as? String {
                        let MarketRef = self.database.collection("markets").document(marketStr)
                        self.retrieveSingleMarket(by: MarketRef){ [] (mkt) in
                            market = mkt
                            // convert timestamp to NSDate
                            guard let stamp = dictionary["order_date"] as? Timestamp else {
                                print("Error converting timestamp to NSDate")
                                return
                            }
                            let date = stamp.dateValue()
                            
                            let order = ReceiptModel(market: market, date: date, total: dictionary["total_cost"] as! Double, numOfItems: dictionary["total_num"] as! Int)
                            
                            completion(order)
                        }
                    }
                }
            }
      }
    }
    
    /// Retrieve the current order of the current customer
    /// Completion will be called with the order
    public func retrieveCurrentOrder(completion: @escaping (Order?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        let customerRef = database.collection("customers").document(uid)
        let marketCollectionRef = database.collection("markets")
        let orderCollectionRef = database.collection("orders")
        let driversCollectionRef = database.collection("drivers")
        // Use transaction
        database.runTransaction { (transaction, errorPointer) -> Any? in
            // All documents to be read
            let customerDoc: DocumentSnapshot
            let orderDoc: DocumentSnapshot
            let marketDoc: DocumentSnapshot
            let driverDoc: DocumentSnapshot
            let deliverySessionDoc: DocumentSnapshot
            do {
                try customerDoc = transaction.getDocument(customerRef)
                guard let currentOrderId = customerDoc.data()?["current_order_id"] as? String else {
                    return nil
                }
                try orderDoc = transaction.getDocument(orderCollectionRef.document(currentOrderId))
                guard let driverId = orderDoc.data()?["driver_id"] as? String, let deliverySessionId = orderDoc.data()?["delivery_session_id"] as? String, let marketId = orderDoc.data()?["market"] as? String else {
                    return nil
                }
                try marketDoc = transaction.getDocument(marketCollectionRef.document(marketId))
                try driverDoc = transaction.getDocument(driversCollectionRef.document(driverId))
                try deliverySessionDoc = transaction.getDocument(driversCollectionRef.document(driverId).collection("delivery_sessions").document(deliverySessionId))
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            // Validate required fields
            guard let driverFirstName = driverDoc.data()?["first_name"] as? String, let driverLastName = driverDoc.data()?["last_name"] as? String, let driverPhoneNum = driverDoc.data()?["phone_num"] as? String, let driverEmail = driverDoc.data()?["email"] as? String, let driverLat = driverDoc.data()?["lat"] as? Double, let driverLon = driverDoc.data()?["lon"] as? Double, let driverImageUrl = driverDoc.data()?["image_url"] as? String else {
                print("DatabaseManager - retrieveCurrentOrder: missing driver fields")
                return nil
            }
            guard let customerAddressDict = customerDoc.data()?["active_address"] as? [String: Any], let addressApt = customerAddressDict["apt"] as? String, let addressBuilding = customerAddressDict["building"] as? String, let addressInstruction = customerAddressDict["instruction"] as? String, let addressTitle = customerAddressDict["title"] as? String, let addressSubtitle = customerAddressDict["subtitle"] as? String, let addressLat = customerAddressDict["lat"] as? Double, let addressLon = customerAddressDict["lon"] as? Double else {
                print("DatabaseManager - retrieveCurrentOrder: missing active address fields")
                return nil
            }
            guard let marketTitle = marketDoc.data()?["name"] as? String, let marketAddressDict = marketDoc.data()?["address"] as? [String: Any], let marketLat = marketAddressDict["lat"] as? Double, let marketLon = marketAddressDict["lon"] as? Double else {
                print("DatabaseManager - retrieveCurrentOrder: missing market fields")
                return nil
            }
            // Instantiate order object and return it
            let driver = Driver(firstName: driverFirstName, lastName: driverLastName, email: driverEmail, phoneNum: driverPhoneNum, imageUrl: driverImageUrl, lat: driverLat, lon: driverLon)
            let customerAddress = Address(title: addressTitle, subtitle: addressSubtitle, lat: addressLat, lon: addressLon, apt: addressApt, building: addressBuilding, instruction: addressInstruction)
            let market = Market(title: marketTitle, lat: marketLat, lon: marketLon, marketID: marketDoc.documentID)
            let order = Order(id: orderDoc.documentID, driver: driver, deliverySessionId: deliverySessionDoc.documentID, driverId: driverDoc.documentID, customerAddress: customerAddress, market: market)
            return order
        } completion: { (object, error) in
            if let error = error {
                print("DatabaseManager - retrieveCurrentOrder: \(error)")
                completion(nil)
            } else if let order = object as? Order {
                print("DatabaseManager - retrieveCurrentOrder: succeeded")
                completion(order)
            }
            completion(nil)
        }
    }
    
    /// Listen to driver location update and call completion with lat and lon
    /// Return listener registration
    public func listenToDriverLocation(order: Order, completion: @escaping (Double, Double) -> Void) -> ListenerRegistration {
        return database.collection("drivers").document(order.driverId)
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("DatabaseManager - listenToDriverLocation: \(error)")
                    return
                }
                guard let document = snapshot, document.exists else {
                    print("DatabaseManager - listenToDriverLocation: driver document \(order.driverId) does not exists")
                    return
                }
                guard let lat = document.get("lat") as? Double, let lon = document.get("lon") as? Double else {
                    print("DatabaseManager - listenToDriverLocation: missing fields")
                    return
                }
                completion(lat, lon)
            }
    }
    
    public func listenToDeliverySession(order: Order, completion: @escaping (OrderState) -> Void) -> ListenerRegistration {
        return database.collection("drivers").document(order.driverId)
            .collection("delivery_sessions").document(order.deliverySessionId)
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("DatabaseManager - listenToDeliverySession: \(error)")
                    return
                }
                guard let document = snapshot, document.exists else {
                    print("DatabaseManager - listenToDeliverySession: driver document \(order.driverId) does not exists")
                    return
                }
                guard let step = document.get("step") as? Int, let orderIds = document.get("order_ids") as? [String] else {
                    print("DatabaseManager - listenToDeliverySession: missing fields")
                    return
                }
                guard let index = orderIds.firstIndex(of: order.id) else {
                    print("DatabaseManager - listenToDeliverySession: order not found")
                    return
                }
                if step == 0 {
                    completion(.accepted)
                } else if index + 1 > step {
                    completion(.toOther)
                } else if index + 1 == step {
                    completion(.toYou)
                } else {
                    completion(.arrived)
                }
            }
    }
    
    // MARK: - Produce

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
    
    // MARK: - Farm
    
    /// retrieve farms with provided category and market reference
    public func retrieveFarms(with category: String, marketRef: DocumentReference, completion: @escaping ((Farm) -> Void)){
        marketRef.collection("farms").whereField("category", isEqualTo: category).getDocuments() { (document, error) in
              if let error = error {
                  print("Error retrieving farms for market: \(error)")
              } else{
                  print("retrieving current category \(category)")
                
                  for document in document!.documents {
                    let dictionary = document.data()
                    let farm = Farm(image: UIImage(named: "Happy"), farmName: dictionary["name"] as! String, image_url: dictionary["image_url"] as! String,farmId: dictionary["farmid"] as! String)
                    completion(farm)
                  }
              }
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
    public func insertAddress2(title: String, subtitle: String, lat: Double, lon: Double, apt: String, building: String, instruction: String) {
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
            "lon": lon,
            "apt": apt,
            "building": building,
            "instruction": instruction
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
            if let document = document, document.exists, let dictionary = document.data() {
                
                
                guard let fetchAddress = dictionary["addresses"] as? [[String : Any]] else {
                    print("no saved address")
                    completion([])
                    return
                }
                    
                for addr in fetchAddress {
                    let title = addr["title"] as! String
                    let subtitle = addr["subtitle"] as! String
                    let lat = addr["lat"] as! Double
                    let lon = addr["lon"] as! Double
                    let apt = addr["apt"] as! String
                    let building = addr["building"] as! String
                    let instruction = addr["instruction"] as! String
                    let newAddr = Address(title: title, subtitle: subtitle, lat: lat, lon: lon, apt: apt, building: building, instruction: instruction)
                    savedAddress.append(newAddr)
                    
                }

                
                completion(savedAddress)
            } else {
                print("Error retrieving saved addr: Document does not exist")
            }
        }
    }
    
    /// set active address
    public func setActiveAddress(title: String, subtitle: String, lat: Double, lon: Double, apt: String, building: String, instruction: String) {
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
            "lon": lon,
            "apt": apt,
            "building": building,
            "instruction": instruction
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
    public func retrieveActiveAddress(completion: @escaping ((String, String, Double, Double, String, String, String) -> Void)){
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        
        let userRef = database.collection("customers").document(uid)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists, let dictionary = document.data() {
                guard let address = dictionary["active_address"] as? [String : Any] else {
                    print("no active address")
                    completion("","",0,0,"","","")
                    return
                }
                
                let title = address["title"] as! String
                let subtitle = address["subtitle"] as! String
                let lat = address["lat"] as! Double
                let lon = address["lon"] as! Double
                let apt = address["apt"] as! String
                let building = address["building"] as! String
                let instruction = address["instruction"] as! String
                
                completion(title, subtitle, lat, lon, apt, building, instruction)
            } else {
                print("Error retrieving active address \(userRef): Document does not exist or error during reading")
            }
        }
    }
    
    /// delete saved address
    public func deleteAddress(title: String, subtitle: String, lat: Double, lon: Double, apt: String, building: String, instruction: String) {
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
            "lon": lon,
            "apt": apt,
            "building": building,
            "instruction": instruction
        ]
        
        print("in deleting ", dataDict)
        database.collection("customers").document(uid).updateData([
            "addresses": FieldValue.arrayRemove([dataDict])
        ]) { (error) in
            if let error = error {
                print("Error inserting address: \(error)")
                return
            }
            print("\(title) address deleted.")
        }
        print("done inserting addr")
    }
    
    
    // MARK: - Payment
    
    /// Inserts a payment method id to current customer
    /// The newly added payment method will be the default
    public func insertPaymentMethod(id: String) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        let dataDict: [String: Any] = [
            "id": id,
        ]
        database.collection("customers").document(uid)
            .collection("payment_methods").document(id).setData(dataDict) { (error) in
                if let error = error {
                    print("Error inserting payment method: \(error)")
                    return
                }
                print("Inserted payment method.")
            }
    }
    
    /// Remove a payment method from the current customer
    public func removePaymentMethod(paymentMethod: PaymentMethod, completion: @escaping () -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        let paymentMethodId = paymentMethod.id
        database.collection("customers").document(uid)
            .collection("payment_methods").document(paymentMethodId)
            .delete { (error) in
                if let error = error {
                    print("Error removing payment method: \(error)")
                } else {
                    completion()
                }
            }
    }
    
    /// Set the payment method as the default one
    public func setDefaultPaymentMethod(as paymentMethod: PaymentMethod, completion: @escaping () -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        let paymentMethodId = paymentMethod.id
        let collectionRef: CollectionReference = database.collection("customers").document(uid)
            .collection("payment_methods")
        // Get all payment methods with is_default equal to true
        collectionRef.whereField("is_default", isEqualTo: true).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting current default payment method: \(error)")
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching payment methods: \(error!)")
                    return
                }
                // Change all others' is_default to false
                for document in documents {
                    collectionRef.document(document.documentID).updateData(["is_default": false])
                }
                // Update current payment method to default
                collectionRef.document(paymentMethodId).updateData(["is_default": true]) { (error) in
                    if let error = error {
                        print("Error updating current payment method: \(error)")
                        return
                    }
                    completion()
                }
            }
    }
    
    /// Listen to current customer's payment methods
    public func listenToAllPaymentMethods(completion: @escaping ([PaymentMethod]) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("customers").document(uid)
            .collection("payment_methods").addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                var paymentMethods: [PaymentMethod] = []
                for document in documents {
                    let dictionary = document.data()
                    if let id = dictionary["id"] as? String, let last4 = (dictionary["card"] as? [String: Any])?["last4"] as? String, let brand = (dictionary["card"] as? [String: Any])?["brand"] as? String, let isDefault = dictionary["is_default"] as? Bool {
                        print("Read payment method: \(brand), \(last4), \(id)")
                        paymentMethods.append(PaymentMethod(id: id, last4: last4, brand: brand, isDefault: isDefault))
                    }
                }
                completion(paymentMethods)
            }
    }
    
    /// Listen to changes in customer data
    public func listenToCustomerUpdates(completion: @escaping ([String: Any]) -> Void) {
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
    
    /// Create order for 1 customer from 1 market
    /// Completion will be called with the new order id
    public func createMarketOrder(market_id: String, total_num: Int, total_cost: Double, orderFromMarket: [[String: Any]], farm_total_cost: [[String: Any]], order_date: Date, phone_num: String, driver_earned: Double, completion: @escaping (String) -> Void) {
        // Use currentUser.uid as document id
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        let dataDict: [String : Any] = [
            "customer": uid,
            "delivery_status": "created",
            "market": market_id,
            "total_num": total_num,
            "total_cost": total_cost,
            "order": orderFromMarket,
            "farm_total_cost": farm_total_cost,
            "order_date": order_date,
            "phone_num": phone_num,
            "driver_earned": driver_earned,
        ]
        // Use batched writes
        let batch = database.batch()
        // Set order data
        let orderRef = database.collection("orders").document()
        batch.setData(dataDict, forDocument: orderRef)
        // Update customer's current order
        let customerRef = database.collection("customers").document(uid)
        batch.updateData(["current_order_id": orderRef.documentID], forDocument: customerRef)
        
        batch.commit { (error) in
            if let error = error {
                print("Error creating new order: \(error)")
                return
            }
            print("Added new order order.")
            completion(orderRef.documentID)
        }
    }
    
    /// Update 'status' field of the payment with 'id'
    public func updatePaymentStatus(id: String, status: String) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("customers").document(uid)
            .collection("payments").document(id)
            .updateData(["payment.status": status]) { (error) in
                if let error = error {
                    print("Error updating payment status for \(id): \(error)")
                    return
                }
                print("Updated payment status for \(id)")
            }
    }
    
    /// Listen to changes to customer's payment with 'orderId'
    /// Completion will be called with the 'paymentId', 'paymentStatus' and 'clientSecret'
    public func listenToPaymentUpdates(orderId: String, completion: @escaping (String?, String?, String?, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("Not signed in")
            return
        }
        let uid = user.uid
        database.collection("customers").document(uid)
            .collection("payments").whereField("order_id", isEqualTo: orderId)
            .addSnapshotListener { (querySnapshot, error) in
                if let error = error {
                    print("Error listening to payment update: \(error)")
                    return
                }
                guard let documents = querySnapshot?.documents, documents.count > 0 else {
                    print("Document does not exist")
                    return
                }
                if let errorMsg = documents[0].data()["error"] as? String {
                    completion(nil, nil, nil, errorMsg)
                    return
                }
                guard let paymentDict = documents[0].data()["payment"] as? [String: Any], let paymentStatus = paymentDict["status"] as? String, let clientSecret = paymentDict["client_secret"] as? String else {
                    print("Error getting 'status' field for order: \(orderId)")
                    return
                }
                completion(documents[0].documentID, paymentStatus, clientSecret, nil)
            }
    }
    
    
    
}





