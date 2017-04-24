//
//  BSUIRXMLParser.swift
//  DailyLabs
//
//  Created by Mikhail Lyapich on 4/24/17.
//  Copyright © 2017 Gleb Kulik. All rights reserved.
//

import Foundation
import SWXMLHash


class BSUIRXMLParser {
    
    static func parseGroupsID(_ xml: XMLIndexer) -> [String:String] {
        var result = [String:String]()
        for group in xml["studentGroupXmlModels"]["studentGroup"].all {
            if let groupName = group["name"].element?.text, let groupID = group["id"].element?.text {
                result[groupName] = groupID
            }
        }
        return result
    }
    
    static func parseSubjects(_ xml: XMLIndexer) -> Set<String> {
        var result = Set<String>()
        for week in xml["scheduleXmlModels"]["scheduleModel"].all{
            for day in week["schedule"].all {
                if let lessonType = day["lessonType"].element?.text, let subj = day["subject"].element!.text, lessonType == "ЛР"{
                    result.insert(subj)
                }
            }
        }
        return result
    }
}
