//
//  CloudFunctionsManager.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/3/15.
//

import Foundation
import Firebase

/// Might not use this class
class CloudFunctionsManager {
    
    static let shared = CloudFunctionsManager()
    
    private lazy var functions = Functions.functions()
    
}
