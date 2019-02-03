//
//  AlamofireRSSParser.swift
//  Pods
//
//  Created by Donald Angelillo on 3/2/16.
//
//

import Foundation
import Alamofire

/**
    This class does the bulk of the work.  Implements the `NSXMLParserDelegate` protocol.
    Unfortunately due to this it's also required to implement the `NSObject` protocol.
    
    And unfortunately due to that there doesn't seem to be any way to make this class have a valid public initializer,
    despite it being marked public.  I would love to have it be publicly accessible because I would like to able to pass
    a custom-created instance of this class with configuration properties set into `responseRSS` (see the commented out overload in Alamofire+Extensions.swift)
*/
open class AlamofireRSSParser: NSObject, XMLParserDelegate {
    var parser: XMLParser? = nil
    var feed: RSSFeed? = nil
    var parsingItems: Bool = false
    
    var currentItem: RSSItem? = nil
    var currentString: String!
    var currentAttributes: [String: String]? = nil
    var parseError: NSError? = nil
    
    private lazy var rfc822DateFormatter: DateFormatter = {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return dateFormatter
    }()
    
    private lazy var rfc822DateFormatter2: DateFormatter = {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return dateFormatter
    }()
    
    private lazy var publishedDateFormatter: DateFormatter = {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }()
    
    private lazy var publishedDateFormatter2: DateFormatter = {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssz"
        return dateFormatter
    }()
    
    open var data: Data? = nil {
        didSet {
            if let data = data {
                self.parser = XMLParser(data: data)
                self.parser?.delegate = self
            }
        }
    }
    
    override init() {
        self.parser = XMLParser();
        
        super.init()
    }
    
    init(data: Data) {
        self.parser = XMLParser(data: data)
        super.init()
        
        self.parser?.delegate = self
    }
    
    
    /**
        Kicks off the RSS parsing.
     
        - Returns: A tuple containing an `RSSFeed` object if parsing was successful (`nil` otherwise) and
            an `NSError` object if an error occurred (`nil` otherwise).
    */
    func parse() -> (feed: RSSFeed?, error: NSError?) {
        self.feed = RSSFeed()
        self.currentItem = nil
        self.currentAttributes = nil
        self.currentString = String()
        
        self.parser?.parse()
        return (feed: self.feed, error: self.parseError)
    }
    
    //MARK: - NSXMLParserDelegate
    open func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        self.currentString = String()
        
        self.currentAttributes = attributeDict
        
        if ((elementName == "item") || (elementName == "entry")) {
            self.currentItem = RSSItem()
        }
    }
    
    open func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let currentItem = self.currentItem {
            //if we're at the item level
            parseItem(elementName, currentItem)
        } else {
             //if we're at the top level
            parseTopLevel(elementName)
        }
    }
    
    open func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.currentString.append(string)
    }
    
    open func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError as NSError?
        self.parser?.abortParsing()
    }
    
    fileprivate func parseItem(_ elementName: String, _ currentItem: RSSItem) {
        
        switch elementName {
        case "item", "entry":
            self.feed?.items.append(currentItem)
        case "title":
            currentItem.title = self.currentString
        case "description", "summary type":
            currentItem.itemDescription = self.currentString
        case "image":
            if let attributes = self.currentAttributes, let url = attributes["url"] {
                    currentItem.image = url
            }
        case "content:encoded", "content":
            currentItem.content = self.currentString
        case "link":
            if let attributes = self.currentAttributes, let link = attributes["href"] {
                currentItem.link = link
            } else {
                currentItem.link = self.currentString
            }
        case "guid", "id":
            currentItem.guid = self.currentString
        case "author":
            currentItem.author = self.currentString
        case "comments":
            currentItem.comments = self.currentString
        case "source":
            currentItem.source = self.currentString
        case "pubDate", "updated":
            if let date = rfc822DateFormatter.date(from: self.currentString) {
                currentItem.pubDate = date
            } else if let date = rfc822DateFormatter2.date(from: self.currentString) {
                currentItem.pubDate = date
            }
        case "published":
            if let date = publishedDateFormatter.date(from: self.currentString) {
                currentItem.pubDate = date
            } else if let date = publishedDateFormatter2.date(from: self.currentString) {
                currentItem.pubDate = date
            }
        case "media:thumbnail":
            if let attributes = self.currentAttributes {
                if let url = attributes["url"] {
                    currentItem.mediaThumbnail = url
                }
            }
        case "media:content":
            if let attributes = self.currentAttributes {
                if let url = attributes["url"] {
                    currentItem.mediaContent = url
                }
            }
        case "enclosure":
            if let attributes = self.currentAttributes {
                currentItem.enclosures = (currentItem.enclosures ?? []) + [attributes]
            }
        case "category":
            if let attributes = self.currentAttributes {
                currentItem.categories = (currentItem.categories ?? []) + [attributes]
            }
            
        default:
            // Do nothing.
            break
        }
    }
    
    fileprivate func parseTopLevel(_ elementName: String) {
        
        switch elementName {
            
        case "title":
            self.feed?.title = self.currentString
        case "description":
            self.feed?.feedDescription = self.currentString
        case "link":
            self.feed?.link = self.currentString
        case "language":
            self.feed?.language = self.currentString
        case "copyright":
            self.feed?.copyright = self.currentString
        case "managingEditor":
            self.feed?.managingEditor = self.currentString
        case "webMaster":
            self.feed?.webMaster = self.currentString
        case "generator":
            self.feed?.generator = self.currentString
        case "docs":
            self.feed?.docs = self.currentString
        case "ttl":
            if let ttlInt = Int(currentString) {
                self.feed?.ttl = NSNumber(value: ttlInt)
            }
        case "pubDate":
            if let date = rfc822DateFormatter.date(from: self.currentString) {
                self.feed?.pubDate = date
            } else if let date = rfc822DateFormatter2.date(from: self.currentString) {
                self.feed?.pubDate = date
            }
        case "published":
            if (elementName == "published") {
                if let date = publishedDateFormatter.date(from: self.currentString) {
                    self.feed?.pubDate = date
                } else if let date = publishedDateFormatter2.date(from: self.currentString) {
                    self.feed?.pubDate = date
                }
            }
        case "lastBuildDate":
            if (elementName == "lastBuildDate") {
                if let date = rfc822DateFormatter.date(from: self.currentString) {
                    self.feed?.lastBuildDate = date
                } else if let date = rfc822DateFormatter2.date(from: self.currentString) {
                    self.feed?.lastBuildDate = date
                }
            }
        case "url":
            self.feed?.image = URL(string: self.currentString)
        default:
            // Do nothing.
            break
        }
    }
}

