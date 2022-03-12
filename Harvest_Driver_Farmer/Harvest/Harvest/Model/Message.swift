//
//  Message.swift
//  Harvest
//
//  Created by Zixuan Li on 2021/3/16.
//

import Foundation
import UIKit
import Firebase
import MessageKit

struct Message{
    var id: String
    var content: String
    var created: Timestamp // when the msg is created
    var senderID: String
    var senderName: String
    var dictionary: [String: Any]{
        return [
            "id": id,
            "content": content,
            "created": created,
            "senderID": senderID,
            "senderName": senderName
        ]
    }
}

extension Message{
    init?(dictionary: [String: Any]){
        guard let id = dictionary["id"] as? String,
              let content = dictionary["content"] as? String,
              let created = dictionary["created"] as? Timestamp,
              let senderID = dictionary["senderID"] as? String,
              let senderName = dictionary["senderName"] as? String
        else {return nil}
        
        self.init(id:id, content: content, created: created, senderID: senderID, senderName: senderName)
    }
}

struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

extension Message: MessageType {

    var sender: SenderType {
        return Sender(senderId: senderID, displayName: senderName)
    }
    
    var messageId: String {
        return id
    }
    
    var sentDate: Date {
        return created.dateValue()
    }
    
    var kind: MessageKind {
        return .text(content)
    }
}
