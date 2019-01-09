import UIKit
import XCTest
import Alamofire
import AlamofireRSSParser

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAtomFeed() {
        
        let expectation = XCTestExpectation(description: "Blah")
        
        let feedUrl = "https://www.xkcd.com/atom.xml"
        
        Alamofire.request(feedUrl).responseRSS { response in
            
            if response.result.isSuccess {
                expectation.fulfill()
            } else {
                XCTFail()
            }
        }
        
        wait(for: [expectation], timeout: 10)
    }
}
