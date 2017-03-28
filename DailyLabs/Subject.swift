//
//  Subject.swift
//  DailyLabs
//
//  Created by Gleb Kulik on 2/11/17.
//  Copyright © 2017 Gleb Kulik. All rights reserved.
//

import Foundation
import RealmSwift

class Subject: Object {
    
    dynamic var name = ""
    dynamic var notes = ""
    let labs = List<Lab>()
    
    // Specify properties to ignore (Realm won't persist these)
    
    //  override static func ignoredProperties() -> [String] {
    //    return []
    //  }
    
}
