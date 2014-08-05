import Foundation

class FreeBSD: GSystem {
    
    init(agent: GAgent) {
        super.init(name: "FreeBSD", agent: agent)
        prefix = ""
        homepage = "http://www.freebsd.org/ports/"
        cmd = "\(prefix)freebsd"
    }
    
    override func list() -> [GPackage] {
        
        index.removeAll(keepCapacity: true)
        items.removeAll(keepCapacity: true)
        
        let indexPath = "~/Library/Application Support/Guigna/FreeBSD/INDEX".stringByExpandingTildeInPath
        if NSFileManager.defaultManager().fileExistsAtPath(indexPath) {
            var lines = (NSString(contentsOfFile: indexPath, encoding: NSUTF8StringEncoding, error: nil) as String).split("\n")
            for line in lines {
                let components = line.split("|")
                var name = components[0]
                var idx = name.rindex("-")
                if idx == NSNotFound {
                    continue
                }
                let version = name.substringFromIndex(idx + 1)
                name = name.substringToIndex(idx)
                let description = components[3]
                let category = components[6]
                let homepage = components[9]
                let pkg = GPackage(name: name, version: version, system: self, status: .Available)
                pkg.categories = category
                pkg.description = description
                pkg.homepage = homepage
                items.append(pkg)
                // self[id] = pkg
            }
            
        } else {
            let url = NSURL(string: "http://www.freebsd.org/ports/master-index.html")
            let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
            let root = xmlDoc.rootElement().nodesForXPath("/*", error: nil)[0] as NSXMLNode
            let names = root.nodesForXPath("//p/strong/a", error: nil) as [NSXMLNode]
            let descriptions = root.nodesForXPath("//p/em", error: nil) as [NSXMLNode]
            var i = 0
            for node in names {
                var name = node.stringValue!
                var idx = name.rindex("-")
                let version = name.substringFromIndex(idx + 1)
                name = name.substringToIndex(idx)
                var category = node.attribute("href")
                category = category.substringToIndex(category.index(".html"))
                var description = descriptions[i].stringValue!
                let pkg = GPackage(name: name, version: version, system: self, status: .Available)
                pkg.categories = category
                pkg.description = description
                items.append(pkg)
                // self[id] = pkg
                i++
            }
        }
        // self.installed() // update status
        return items as [GPackage]
    }
    
    
    override func info(item: GItem) -> String { // TODO: Offline mode
        let category = item.categories!.split()[0]
        var itemName = item.name
        var pkgDescr = NSString(contentsOfURL: NSURL(string: "http://svnweb.freebsd.org/ports/head/\(category)/\(item.name)/pkg-descr?view=co"), encoding: NSUTF8StringEncoding, error: nil)
        if pkgDescr.hasPrefix("<!DOCTYPE") { // 404 File Not Found
            itemName = itemName.lowercaseString
            pkgDescr = NSString(contentsOfURL: NSURL(string: "http://svnweb.freebsd.org/ports/head/\(category)/\(item.name)/pkg-descr?view=co"), encoding: NSUTF8StringEncoding, error: nil)
        }
        if pkgDescr.hasPrefix("<!DOCTYPE") { // 404 File Not Found
            pkgDescr = "[Info not reachable]"
        }
        return pkgDescr
    }
    
    
    override func home(item: GItem) -> String {
        if item.homepage != nil { // already available from INDEX
            return item.homepage
        } else {
            let pkgDescr = self.info(item)
            if pkgDescr != "[Info not reachable]" {
                for line in pkgDescr.split("\n").reverse() {
                    let idx = line.index("WWW:")
                    if idx != NSNotFound {
                        return line.substringFromIndex(idx + 4).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    }
                }
            }
        }
        return self.log(item) // TODO
    }
    
    override func log(item: GItem!) -> String {
        if item != nil  {
            let category = item.categories!.split()[0]
            return "http://www.freshports.org/\(category)/\(item.name)"
        } else {
            return "http://www.freshports.org"
        }
    }
    
    override func contents(item: GItem) -> String {
        let category = item.categories!.split()[0]
        var itemName = item.name
        var pkgPlist = NSString(contentsOfURL: NSURL(string: "http://svnweb.freebsd.org/ports/head/\(category)/\(item.name)/pkg-plist?view=co"), encoding: NSUTF8StringEncoding, error: nil)
        if pkgPlist.hasPrefix("<!DOCTYPE") { // 404 File Not Found
            itemName = itemName.lowercaseString
            pkgPlist = NSString(contentsOfURL: NSURL(string: "http://svnweb.freebsd.org/ports/head/\(category)/\(item.name)/pkg-plist?view=co"), encoding: NSUTF8StringEncoding, error: nil)
        }
        if pkgPlist.hasPrefix("<!DOCTYPE") { // 404 File Not Found
            pkgPlist = ""
        }
        return pkgPlist
    }
    
    override func cat(item: GItem) -> String {
        let category = item.categories!.split()[0]
        var itemName = item.name
        var makefile = NSString(contentsOfURL: NSURL(string: "http://svnweb.freebsd.org/ports/head/\(category)/\(item.name)/Makefile?view=co"), encoding: NSUTF8StringEncoding, error: nil)
        if makefile.hasPrefix("<!DOCTYPE") { // 404 File Not Found
            itemName = itemName.lowercaseString
            makefile = NSString(contentsOfURL: NSURL(string: "http://svnweb.freebsd.org/ports/head/\(category)/\(item.name)/Makefile?view=co"), encoding: NSUTF8StringEncoding, error: nil)
        }
        if makefile.hasPrefix("<!DOCTYPE") { // 404 File Not Found
            makefile = "[Makefile not reachable]"
        }
        return makefile
    }
    
    // TODO: deps => parse requirements:
    // http://www.FreeBSD.org/cgi/ports.cgi?query=%5E' + '%@-%@' item.name-item.version
    
}

