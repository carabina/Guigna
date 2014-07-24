import Foundation

class MacPorts: GSystem {
    
    init(agent: GAgent) {
        super.init(name: "MacPorts", agent: agent)
        prefix = "/opt/local"
        homepage = "http://www.macports.org"
        cmd = "\(prefix)/bin/port"
    }
    
    override func list() -> [GPackage] {
        
        index.removeAll(keepCapacity: true)
        items.removeAll(keepCapacity: true)
        
        var pkgs = [GPackage]()
        pkgs.reserveCapacity(50000)
        
        if agent.appDelegate!.defaults["MacPortsParsePortIndex"] == false {
            var outputLines = output("\(cmd) list").split("\n")
            outputLines.removeLast()
            let whitespaceCharacterSet = NSCharacterSet.whitespaceCharacterSet()
            for line in outputLines {
                var components = line.split("@")
                let name = components[0].stringByTrimmingCharactersInSet(whitespaceCharacterSet)
                components = components[1].split()
                let version = components[0]
                // let revision = "..."
                let categories = components[components.count - 1].split("/")[0]
                var pkg = GPackage(name: name, version: version, system: self, status: .Available)
                // var pkg = GPackage(name: name, version: "\(version)_\(revision)", system: self, status: .Available)
                pkg.categories = categories
                // pkg.description = description!
                // pkg.license = license
                // if (self.mode == GOnlineMode) {
                //    pkg.homepage = homepage;
                // }
                // items += pkg // FIXME: slow
                pkgs += pkg
                self[name] = pkg
            }
        
        } else {
            var portIndex = "" as NSString
            if mode == GMode.Online { // TODO: fetch PortIndex
                portIndex = NSString(contentsOfFile: "~/Library/Application Support/Guigna/MacPorts/PortIndex".stringByExpandingTildeInPath, encoding: NSUTF8StringEncoding, error: nil)
            } else {
                portIndex = NSString(contentsOfFile: "\(prefix)/var/macports/sources/rsync.macports.org/release/tarballs/ports/PortIndex", encoding: NSUTF8StringEncoding, error: nil)
            }
            let s =  NSScanner(string: portIndex)
            s.charactersToBeSkipped = NSCharacterSet(charactersInString: "")
            let spaceOrReturn = NSCharacterSet.whitespaceAndNewlineCharacterSet()
            var str: NSString? = nil
            var loc: Int
            var name: NSString? = nil
            var key: NSString? = nil
            var value: NSMutableString = ""
            var version: String?
            var revision: String?
            var categories: String?
            var description: String?
            var homepage: String?
            var license: String?
            while true {
                if !s.scanUpToString(" ", intoString: &name) {
                    break
                }
                s.scanUpToString("\n", intoString: nil)
                s.scanString("\n", intoString: nil)
                while true {
                    s.scanUpToString(" ", intoString: &key)
                    s.scanString(" ", intoString: nil)
                    loc = s.scanLocation
                    var nextIsBrace = s.scanString("{", intoString: nil)
                    s.scanLocation = loc
                    if nextIsBrace {
                        value.setString("")
                        s.scanString("{", intoString: nil)
                        do {
                            var range = value.rangeOfString("{")
                            if range.location != NSNotFound {
                                value.replaceCharactersInRange(range, withString: "")
                            }
                            if s.scanUpToString("}", intoString: &str) {
                                value.appendString(str)
                            }
                            s.scanString("}", intoString: nil)
                        } while value.containsString("{")
                    } else {
                        s.scanUpToCharactersFromSet(spaceOrReturn, intoString: &str)
                        value.setString(str)
                    }
                    if key == "version" {
                        version = value
                    }
                    if key == "revision" {
                        revision = value
                    }
                    if key == "categories" {
                        categories = value
                    }
                    if key == "description" {
                        description = value
                    }
                    if key == "homepage" {
                        homepage = value
                    }
                    if key == "license" {
                        license = value
                    }
                    loc = s.scanLocation
                    var nextIsReturn = s.scanString("\n", intoString: nil)
                    s.scanLocation = loc
                    if nextIsReturn {
                        s.scanString("\n", intoString: nil)
                        break
                    }
                    s.scanString(" ", intoString: nil)
                }
                var pkg = GPackage(name: name!, version: "\(version!)_\(revision!)", system: self, status: .Available)
                pkg.categories = categories
                pkg.description = description!
                pkg.license = license
                // if (self.mode == GOnlineMode) {
                //    pkg.homepage = homepage;
                // }
                // items += pkg // FIXME: slow
                pkgs += pkg
                self[name!] = pkg
            }
        }
        items = pkgs
        self.installed() // update status
        return pkgs
    }
    
    
    override func installed() -> [GPackage] {
        
        if self.isHidden {
            return items.filter { $0.status != .Available} as [GPackage]
        }
        var pkgs = [GPackage]()
        pkgs.reserveCapacity(50000)
        
        if mode == GMode.Online { // workaround otherwise enum value not recognized the first time it is encountered
            return pkgs
        }
        
        var outputLines = output("\(cmd) installed").split("\n")
        outputLines.removeLast()
        outputLines.removeAtIndex(0)
        let itemsCount = items.count
        var notInactiveItems = items.filter { $0.status != .Inactive}
        if itemsCount != notInactiveItems.count {
            items = notInactiveItems
            self.agent.appDelegate!.removeItems({ $0.status == .Inactive && $0.system === self}) // TODO: ugly
        }
        var status: GStatus
        for pkg in items as [GPackage] {
            status = pkg.status
            pkg.installed = nil
            if status != .Updated && status != .New {
                pkg.status = .Available
            }
        }
        self.outdated() // index outdated ports
        let whitespaceCharacterSet = NSCharacterSet.whitespaceCharacterSet()
        for line in outputLines {
            var components = line.stringByTrimmingCharactersInSet(whitespaceCharacterSet).split()
            var name = components[0]
            var version = components[1].substringFromIndex(1)
            var variants: String! = nil
            let sep = version.index("+")
            if sep != NSNotFound {
                variants = version.substringFromIndex(sep + 1).split("+").join()
                version = version.substringToIndex(sep)
            }
            if variants != nil {
                variants = variants.stringByReplacingOccurrencesOfString(" ", withString: "+")
                version = "\(version) \(variants)"
            }
            status = components.count == 2 ? .Inactive : .UpToDate
            var pkg: GPackage! = self[name]
            var latestVersion: String = (pkg == nil) ? "" : pkg.version
            if status == .Inactive {
                pkg = nil
            }
            if pkg == nil {
                pkg = GPackage(name: name, version: latestVersion, system: self, status: status)
                if status != .Inactive {
                    self[name] = pkg
                } else {
                    items += pkg
                    self.agent.appDelegate!.addItem(pkg)  // TODO: ugly
                }
            } else {
                if pkg.status == .Available {
                    pkg.status = status
                }
            }
            pkg.installed = version
            pkg.options = variants
            pkgs += pkg
        }
        return pkgs
    }
    
    
    override func outdated() -> [GPackage] {
        
        if self.isHidden {
            return items.filter { $0.status == .Outdated} as [GPackage]
        }
        
        var pkgs = [GPackage]()
        pkgs.reserveCapacity(50000)
        
        if mode == .Online {
            return pkgs
        }
        
        var outputLines = output("\(cmd) outdated").split("\n")
        outputLines.removeLast()
        outputLines.removeAtIndex(0)
        for line in outputLines {
            let components = line.split(" < ")[0].split()
            let name = components[0]
            let version = components[components.count-1]
            var pkg = self[name]
            var latestVersion: String = (pkg == nil) ? "" : pkg.version
            if pkg == nil {
                pkg = GPackage(name: name, version: latestVersion, system: self, status: .Outdated)
                self[name] = pkg
            } else {
                pkg.status = .Outdated
            }
            pkg.installed = version
            pkgs += pkg
        }
        return pkgs
    }
    
    
    override func inactive() -> [GPackage] {
        
        if self.isHidden {
            return items.filter { $0.status == .Inactive} as [GPackage]
        }
        var pkgs = [GPackage]()
        pkgs.reserveCapacity(50000)
        
        if mode == .Online {
            return pkgs
        }
        
        for pkg in installed() {
            if pkg.status == .Inactive {
                pkgs += pkg
            }
        }
        return pkgs
    }
    
    
    override func info(item: GItem) -> String {
        if self.isHidden {
            return super.info(item)
        }
        if mode == .Online {
            // TODO: format keys and values
            var info = agent.nodes(URL: "http://www.macports.org/ports.php?by=name&substr=\(item.name)", XPath: "//div[@id=\"content\"]/dl")[0].stringValue!
            let keys = agent.nodes(URL: "http://www.macports.org/ports.php?by=name&substr=\(item.name)", XPath: "//div[@id=\"content\"]/dl//i")
            var stringValue: String!
            for key in keys {
                stringValue = key.stringValue!
                info = info.stringByReplacingOccurrencesOfString(stringValue, withString: "\n\n\(stringValue)\n")
            }
            return info
        }
        let columns = agent.appDelegate!.shellColumns
        return output("/bin/sh -c export__COLUMNS=\(columns)__;__\(cmd)__info__\(item.name)")
    }
    
    
    override func home(item: GItem) -> String {
        if self.isHidden {
            var homepage: String
            for line in cat(item).split("\n") {
                if line.contains("homepage") {
                    homepage = line.substringFromIndex(8).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    if homepage.hasPrefix("http") {
                        return homepage
                    }
                }
            }
            return log(item)
        }
        if mode == .Online {
            return item.homepage
        }
        let url = output("\(cmd) -q info --homepage \(item.name)")
        return url.substringToIndex(url.length - 1)
    }
    
    override func log(item: GItem!) -> String {
        if item != nil {
            let category = item.categories!.split()[0]
            return "http://trac.macports.org/log/trunk/dports/\(category)/\(item.name)/Portfile"
        } else {
            return "http://trac.macports.org/timeline"
        }
    }
    
    override func contents(item: GItem) -> String {
        if self.isHidden || mode == .Online {
            return "[Not Available]"
        }
        return output("\(cmd) contents \(item.name)")
    }
    
    override func cat(item: GItem) -> String {
        if self.isHidden || mode == .Online {
            return NSString(contentsOfURL: NSURL(string: "http://trac.macports.org/browser/trunk/dports/\(item.categories!.split()[0])/\(item.name)/Portfile?format=txt"), encoding: NSUTF8StringEncoding, error:nil)
        }
        return output("\(cmd) cat \(item.name)")
    }
    
    override func deps(item: GItem) -> String {
        if self.isHidden || mode == .Online {
            return "[Cannot compute the dependencies now]"
        }
        return output("\(cmd) rdeps --index \(item.name)")
    }
    
    override func dependents(item: GItem) -> String {
        if self.isHidden || mode == .Online {
            return ""
        }
        // TODO only when status == installed
        if item.status != .Available {
            return output("\(cmd) dependents \(item.name)")
        } else {
            return "[\(item.name) not installed]"
        }
    }
    
    override func options(pkg: GPackage) -> String! {
        var variants: String! = nil
        var infoOutput = output("\(cmd) info --variants \(pkg.name)").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if infoOutput.length > 10  {
            variants = infoOutput.substringFromIndex(10).split(", ").join()
        }
        return variants
    }
    
    override func installCmd(pkg: GPackage) -> String {
        var variants: String? = pkg.markedOptions
        if variants == nil {
            variants = ""
        } else {
            variants = "+" + variants!.stringByReplacingOccurrencesOfString(" ", withString: "+")
        }
        return "sudo \(cmd) install \(pkg.name) \(variants)"
    }
    
    override func uninstallCmd(pkg: GPackage) -> String {
        if pkg.status == .Outdated || pkg.status == .Updated {
            return "sudo \(cmd) -f uninstall \(pkg.name) ; sudo \(cmd) clean --all \(pkg.name)"
        } else {
            return "sudo \(cmd) -f uninstall \(pkg.name) @\(pkg.installed)"
        }
    }
    
    override func deactivateCmd(pkg: GPackage) -> String {
        return "sudo \(cmd) deactivate \(pkg.name)"
    }
    
    override func upgradeCmd(pkg: GPackage) -> String {
        return "sudo \(cmd) upgrade \(pkg.name)"
    }
    
    override func fetchCmd(pkg: GPackage) -> String {
        return "sudo \(cmd) fetch \(pkg.name)"
    }
    
    override func cleanCmd(pkg: GPackage) -> String {
        return "sudo \(cmd) clean --all \(pkg.name)"
    }
    
    override var updateCmd: String! {
    get {
        if mode == .Online {
            return "sudo cd ; cd ~/Library/Application\\ Support/Guigna/Macports ; /usr/bin/rsync -rtzv rsync://rsync.macports.org/release/tarballs/PortIndex_darwin_13_i386/PortIndex PortIndex"
        } else {
            return "sudo \(cmd) -d selfupdate"
        }
    }
    }
    
    override var hideCmd: String! {
    get {
        return "sudo mv \(prefix) \(prefix)_off"}
    }
    
    override var unhideCmd: String! {
    get {
        return "sudo mv \(prefix)_off \(prefix)"}
    }
    
}

