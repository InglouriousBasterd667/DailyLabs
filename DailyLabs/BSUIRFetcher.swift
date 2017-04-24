//
//  BSUIRFetcher.swift
//  DailyLabs
//
//  Created by Mikhail Lyapich on 4/23/17.
//  Copyright © 2017 Gleb Kulik. All rights reserved.
//

import Foundation
import SWXMLHash

class XMLFetcher {
    
static func fetch(from requestURL: URL, _ completionHandler: @escaping (XMLIndexer) -> Void) {
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest as URLRequest) { data, response, error in
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            if let data = data, statusCode == 200 {
                let xml = SWXMLHash.parse(data)
                completionHandler(xml)
            }
        }
        task.resume()
    }
}
