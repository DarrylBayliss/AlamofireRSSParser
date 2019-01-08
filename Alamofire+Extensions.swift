//
//  Alamofire+Extensions.swift
//  Alamofire
//
//  Created by Darryl Bayliss on 08/01/2019.
//

import Foundation

extension Alamofire.DataRequest {
    /**
     Creates a response serializer that returns an `RSSFeed` object initialized from the response data.
     
     - Returns: An RSS response serializer.
     */
    public static func RSSResponseSerializer() -> DataResponseSerializer<RSSFeed> {
        return DataResponseSerializer { request, response, data, error in
            guard error == nil else {
                return .failure(error!)
            }
            
            guard let validData = data else {
                let failureReason = "Data could not be serialized. Input data was nil."
                let error = NSError(domain: "com.alamofirerssparser", code: -6004, userInfo: [NSLocalizedFailureReasonErrorKey: failureReason])
                return .failure(error)
            }
            
            let parser = AlamofireRSSParser(data: validData)
            
            let parsedResults: (feed: RSSFeed?, error: NSError?) = parser.parse()
            
            if let feed = parsedResults.feed {
                return .success(feed)
            } else {
                return .failure(parsedResults.error!)
            }
        }
    }
    
    
    /**
     Adds a handler to be called once the request has finished.
     
     - Parameter completionHandler: A closure to be executed once the request has finished.
     
     - Returns: The request.
     */
    @discardableResult
    public func responseRSS(_ completionHandler: @escaping (DataResponse<RSSFeed>) -> Void) -> Self {
        return response(
            responseSerializer: DataRequest.RSSResponseSerializer(),
            completionHandler: completionHandler
        )
    }
    
    
    //public func responseRSS(parser parser: AlamofireRSSParser?, completionHandler: Response<RSSFeed, NSError> -> Void) -> Self {
    //  return response(responseSerializer: Request.RSSResponseSerializer(parser), completionHandler: completionHandler)
    //}
}
