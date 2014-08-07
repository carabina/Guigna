import Foundation

class ITunes: GSystem {
    
    init(agent: GAgent) {
        super.init(name: "iTunes", agent: agent)
        prefix = "" // TODO
        homepage = "https://itunes.apple.com/genre/ios/id36?mt=8"
        cmd = "/Applications/iTunes.app/Contents/MacOS/iTunes"
    }
    
    override func list() -> [GPackage] {
        
        index.removeAll(keepCapacity: true)
        items.removeAll(keepCapacity: true)
        
        items = installed()
        return items as [GPackage]
    }
    
    
    override func installed() -> [GPackage] {
        
        var pkgs = [GPackage]()
        pkgs.reserveCapacity(1000)
        let fileManager = NSFileManager.defaultManager()
        let contents = fileManager.contentsOfDirectoryAtPath("~/Music/iTunes/iTunes Media/Mobile Applications".stringByExpandingTildeInPath, error: nil) as [String]
        for filename in contents {
            let ipa = "~/Music/iTunes/iTunes Media/Mobile Applications/\(filename)".stringByExpandingTildeInPath
            let idx = filename.rindex(" ")
            if idx == NSNotFound {
                continue
            }
            let version = filename.substring(idx + 1, filename.length - idx - 5)
            var escapedIpa = ipa.stringByReplacingOccurrencesOfString(" ", withString: "__")
            var plist = output("/usr/bin/unzip -p \(escapedIpa) iTunesMetadata.plist")
            if  plist == nil { // binary plist
                escapedIpa = ipa.stringByReplacingOccurrencesOfString(" ", withString: "\\__")
                plist = output("/bin/sh -c /usr/bin/unzip__-p__\(escapedIpa)__iTunesMetadata.plist__|__plutil__-convert__xml1__-o__-__-")
            }
            let metadata = plist.propertyList() as NSDictionary
            let name = metadata["itemName"]! as String
            let pkg = GPackage(name: name, version: "", system: self, status: .UpToDate)
            pkg.id = filename.substringToIndex(filename.length - 4)
            pkg.installed = version
            pkg.categories = metadata["genre"]! as? String
            pkgs.append(pkg)
        }
        //    for pkg in installed() {
        //        index[pkg.key].status = pkg.status
        //    }
        return pkgs
    }
    
    
    override func info(item: GItem) -> String {
        return cat(item)
    }
    
    override func home(item: GItem) -> String {
        var homepage = self.homepage
        let ipa = "~/Music/iTunes/iTunes Media/Mobile Applications/\(item.id).ipa".stringByExpandingTildeInPath
        var escapedIpa = ipa.stringByReplacingOccurrencesOfString(" ", withString: "__")
        var plist = output("/usr/bin/unzip -p \(escapedIpa) iTunesMetadata.plist")
        if  plist == nil { // binary plist
            escapedIpa = ipa.stringByReplacingOccurrencesOfString(" ", withString: "\\__")
            plist = output("/bin/sh -c /usr/bin/unzip__-p__\(escapedIpa)__iTunesMetadata.plist__|__plutil__-convert__xml1__-o__-__-")
        }
        let metadata = plist.propertyList() as NSDictionary
        let itemId: Int = metadata["itemId"]! as Int
        let url = NSURL(string: "http://itunes.apple.com/app/id\(itemId)")
        let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
        let mainDiv = xmlDoc.rootElement().nodesForXPath("//div[@id=\"main\"]", error: nil)[0] as NSXMLNode
        let links = mainDiv["//div[@class=\"app-links\"]/a"]
        // TODO: get screenshots via JSON
        let screenshotsImgs = mainDiv["//div[contains(@class, \"screenshots\")]//img"]
        var screenshots = ""
        var i: Int = 0
        for img in screenshotsImgs {
            let url = img.attribute("src")
            if i > 0 {
                screenshots += " "
            }
            screenshots += url
            i++
        }
        item.screenshots = screenshots
        homepage = links[0].attribute("href")
        if homepage == "http://" {
            homepage = links[1].attribute("href")
        }
        return homepage
    }
    
    override func log(item: GItem!) -> String {
        if item == nil {
            return self.homepage
        } else {
            let ipa = "~/Music/iTunes/iTunes Media/Mobile Applications/\(item.id).ipa".stringByExpandingTildeInPath
            var escapedIpa = ipa.stringByReplacingOccurrencesOfString(" ", withString: "__")
            var plist = output("/usr/bin/unzip -p \(escapedIpa) iTunesMetadata.plist")
            if  plist == nil { // binary plist
                escapedIpa = ipa.stringByReplacingOccurrencesOfString(" ", withString: "\\__")
                plist = output("/bin/sh -c /usr/bin/unzip__-p__\(escapedIpa)__iTunesMetadata.plist__|__plutil__-convert__xml1__-o__-__-")
            }
            let metadata = plist.propertyList() as NSDictionary
            let itemId: Int = metadata["itemId"]! as Int
            return "http://itunes.apple.com/app/id\(itemId)"
        }
    }
    
    override func contents(item: GItem) -> String {
        let ipa = "~/Music/iTunes/iTunes Media/Mobile Applications/\(item.id).ipa".stringByExpandingTildeInPath
        var escapedIpa = ipa.stringByReplacingOccurrencesOfString(" ", withString: "__")
        return output("/usr/bin/zipinfo -1 \(escapedIpa)")
    }
    
    override func cat(item: GItem) -> String {
        let ipa = "~/Music/iTunes/iTunes Media/Mobile Applications/\(item.id).ipa".stringByExpandingTildeInPath
        var escapedIpa = ipa.stringByReplacingOccurrencesOfString(" ", withString: "__")
        var plist = output("/usr/bin/unzip -p \(escapedIpa) iTunesMetadata.plist")
        if  plist == nil { // binary plist
            escapedIpa = ipa.stringByReplacingOccurrencesOfString(" ", withString: "\\__")
            plist = output("/bin/sh -c /usr/bin/unzip__-p__\(escapedIpa)__iTunesMetadata.plist__|__plutil__-convert__xml1__-o__-__-")
        }
        let metadata = plist.propertyList() as NSDictionary
        return metadata.description as String
    }
    
    
}

