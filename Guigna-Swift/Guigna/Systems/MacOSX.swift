import Foundation

class MacOSX: GSystem {
    
    init(agent: GAgent) {
        super.init(name: "Mac OS X", agent: agent)
        prefix = "" // TODO
        homepage = "http://support.apple.com/downloads/"
        cmd = "/usr/sbin/pkgutil"
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
        
        var pkgIds = output("/usr/sbin/pkgutil --pkgs").split("\n")
        pkgIds.removeLast()
        
        let history = (NSArray(contentsOfFile: "/Library/Receipts/InstallHistory.plist") as Array).reverse()
        var keepPkg: Bool
        for dict in history as [NSDictionary] {
            keepPkg = false
            var ids = dict["packageIdentifiers"]! as [String]
            for pkgId in ids {
                if let idx = find(pkgIds, pkgId) {
                    keepPkg = true
                    pkgIds.removeAtIndex(idx)
                }
            }
            if !keepPkg {
                continue
            }
            let name = dict["displayName"]! as String
            var version = dict["displayVersion"]! as String
            var category = dict["processName"]! as String
            category = category.stringByReplacingOccurrencesOfString(" ", withString: "").lowercaseString
            if category == "installer" {
                let plist = output("/usr/sbin/pkgutil --pkg-info-plist \(ids[0])").propertyList() as NSDictionary
                version = plist["pkg-version"]! as String
            }
            var pkg = GPackage(name: name, version: "", system: self, status: .UpToDate)
            pkg.id = ids.join()
            pkg.categories = category
            pkg.description = pkg.id!
            pkg.installed = version
            // TODO: pkg.version
            pkgs += pkg
        }
        //    for pkg in installed() {
        //        index[pkg key].status = pkg.status
        //    }
        return pkgs
    }
    
    
    override func outdated() -> [GPackage] {
        var pkgs = [GPackage]()
        // TODO: sudo /usr/sbin/softwareupdate --list
        return pkgs
    }
    
    
    override func inactive() -> [GPackage] {
        var pkgs = [GPackage]()
        return pkgs
    }
    
    
    override func info(item: GItem) -> String {
        var info = ""
        for pkgId in item.id.split() {
            info += output("/usr/sbin/pkgutil --pkg-info \(pkgId)")
            info += "\n"
        }
        return info
    }
    
    override func home(item: GItem) -> String {
        var homeppage = "http://support.apple.com/downloads/"
        if item.categories == "storeagent" || item.categories == "storedownloadd" {
            let url = "http://itunes.apple.com/lookup?bundleId=\(item.id)"
            let data = NSData(contentsOfURL: NSURL(string: url))
            let results = ((NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as NSDictionary)["results"]! as NSArray)
            if results.count > 0 {
                let pkgId = (results[0] as NSDictionary)["trackId"]!.stringValue!
                let url = NSURL(string: "http://itunes.apple.com/app/id\(pkgId)")
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
            }
        }
        return homepage
    }
    
    override func log(item: GItem!) -> String {
        var page = "http://support.apple.com/downloads/"
        if item != nil {
            if item.categories == "storeagent" || item.categories == "storedownloadd" {
                let url = "http://itunes.apple.com/lookup?bundleId=\(item.id)"
                let data = NSData(contentsOfURL: NSURL(string: url))
                let results = ((NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as NSDictionary)["results"]! as NSArray)
                if results.count > 0 {
                    let pkgId = (results[0] as NSDictionary)["trackId"]!.stringValue!
                    page = "http://itunes.apple.com/app/id" + pkgId
                }
            }
        }
        return page
    }
    
    override func contents(item: GItem) -> String {
        var contents = ""
        for pkgId in item.id.split() {
            let plist = output("\(cmd) --pkg-info-plist \(pkgId)").propertyList() as NSDictionary
            var files = output("\(cmd) --files \(pkgId)").split("\n")
            files.removeLast()
            for file in files {
                contents += NSString.pathWithComponents([plist["volume"]!, plist["install-location"]!, file])
                contents += ("\n")
            }
        }
        return contents
    }
    
    override func cat(item: GItem) -> String {
        return "TODO"
    }
    
    
    override func uninstallCmd(pkg: GPackage) -> String {
        // SEE: https://github.com/caskroom/homebrew-cask/blob/master/lib/cask/pkg.rb
        var commands = [String]()
        let fileManager = NSFileManager.defaultManager()
        var dirsToDelete = [String]()
        var isDir: ObjCBool = true
        for pkgId in pkg.id.split() {
            let plist = output("\(cmd) --pkg-info-plist \(pkgId)").propertyList() as NSDictionary
            var dirs = output("\(cmd) --only-dirs --files \(pkgId)").split("\n")
            dirs.removeLast()
            for dir in dirs {
                let dirPath: NSString = NSString.pathWithComponents([plist["volume"]!, plist["install-location"]!, dir])
                let fileAttributes = fileManager.attributesOfItemAtPath(dirPath, error: nil) as NSDictionary
                if (!(fileAttributes.fileOwnerAccountID() == 0) && !dirPath.hasPrefix("/usr/local"))
                    || dirPath.containsString(pkg.name)
                    || dirPath.containsString(".")
                    || dirPath.hasPrefix("/opt/") {
                        if (dirsToDelete.filter { dirPath.containsString($0) }).count == 0 {
                            dirsToDelete += dirPath
                            commands += "sudo rm -r \"\(dirPath)\""
                        }
                }
            }
            var files = output("\(cmd) --files \(pkgId)").split("\n") // links are not detected with --only-files
            files.removeLast()
            for file in files {
                let filePath = NSString.pathWithComponents([plist["volume"]!, plist["install-location"]!, file])
                if !(fileManager.fileExistsAtPath(filePath, isDirectory: &isDir) && (isDir == true)) {
                    if (dirsToDelete.filter { filePath.contains($0) }).count == 0 {
                        commands += "sudo rm \"\(filePath)\""
                    }
                }
            }
            commands += "sudo \(cmd) --forget \(pkgId)"
        }
        return commands.join(" ; ")
        
        // TODO: disable Launchd daemons, clean Application Support, Caches, Preferences
        // SEE: https://github.com/caskroom/homebrew-cask/blob/master/lib/cask/artifact/pkg.rb
    }
    
}

