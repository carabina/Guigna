import Foundation
import WebKit

protocol GAppDelegate {
    var defaults: NSUserDefaultsController! { get set }
    func log(text: String)
    // var allPackages: [GPackage] { get set } // to avoid in Swift since in returns a copy
    func addItem(item: GItem) // to add an inactive package without requiring a copy of allPackages
    func removeItem(item: GItem) // TODO
    func removeItems(excludeElement: GItem -> Bool) // to remove inactive packages from allPackages in Swift
    var shellColumns: Int { get }
}

extension Array {
    
    func join() -> String {
        return self.bridgeToObjectiveC().componentsJoinedByString(" ")
    }
    
    func join(separator: String) -> String {
        return self.bridgeToObjectiveC().componentsJoinedByString(separator)
    }
    
}


extension String {
    
    subscript(index: Int) -> Character {
        return self[advance(startIndex, index)]
    }
    
    subscript(range: Range<Int>) -> String {
        return self[Range(start: advance(startIndex, range.startIndex), end: advance(startIndex, range.endIndex))]
    }
    
    func split() -> Array<String> {
        return self.componentsSeparatedByString(" ")
    }
    
    func split(delimiter: String) -> Array<String> {
        return self.componentsSeparatedByString(delimiter)
    }
    
    var length: Int {
    get {
        return (self as NSString).length
    }
    }
    
    func index(string: String) -> Int {
        return (self as NSString).rangeOfString(string).location
    }
    
    func rindex(string: String) -> Int {
        return (self as NSString).rangeOfString(string, options: .BackwardsSearch).location
    }
    
    func contains(string: String) -> Bool {
        return (self as NSString).containsString(string)
    }
    
//    func substring(location: Int, _ length: Int) -> String {
//        return (self as NSString).substringWithRange(NSMakeRange(location, length))
//    }
    
    func substring(location: Int, _ length: Int) -> String {
        return self[Range(start: location, end: location + length)]
    }
    
//    func substringFromIndex(index: Int) -> String {
//        return (self as NSString).substringFromIndex(index)
//    }
//    
//    func substringToIndex(index: Int) -> String {
//        return (self as NSString).substringToIndex(index)
//    }
    
    
    func substringFromIndex(index: Int) -> String {
        return self[Range(start: index, end: countElements(self))]
    }
    
    func substringToIndex(index: Int) -> String {
        return self[Range(start: 0, end: index)]
    }
    
}


extension NSXMLNode {
    
    func nodesForXPath(xpath: String) -> [NSXMLNode] { // FIXME: doesn't work with GAgent childnodes
        return self.nodesForXPath(xpath, error: nil) as [NSXMLNode]
    }
    
    subscript(xpath: String) -> [NSXMLNode] {
        get {
            return self.nodesForXPath(xpath)
        }
    }
    
    func attribute(name: String) -> String! {
        if let attribute = (self as NSXMLElement).attributeForName(name) {
            return attribute.stringValue!
        } else {
            return nil
        }
    }
    
    var href: String { // FIXME: coompiling error when used
    get {
        return (self as NSXMLElement).attributeForName("href").stringValue!
    }
    }
}


extension NSUserDefaultsController {
    subscript(key: String) -> NSObject! {
        get {
            if let value = self.values.valueForKey(key) as NSObject! {
                return value
            } else {
                return nil
            }
        }
        set(newValue) {
            self.values.setValue(newValue, forKey: key)
        }
    }
}

extension WebView {
    
    override public func swipeWithEvent(event: NSEvent) {
        let x = event.deltaX
        if x < 0 && self.canGoForward {
            self.goForward()
        } else if x > 0 && self.canGoBack {
            self.goBack()
        }
    }
    
    override public func magnifyWithEvent(event: NSEvent) {
        var multiplier: CFloat = self.textSizeMultiplier * CFloat(event.magnification + 1.0)
        self.textSizeMultiplier = multiplier
    }
    
}
