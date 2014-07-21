import Foundation

class Pkgsrc: GSystem {
    
    init(agent: GAgent) {
        super.init(name: "pkgsrc", agent: agent)
        prefix = "/usr/pkg"
        homepage = "http://www.pkgsrc.org"
        cmd = "\(prefix)/sbin/pkg_info"
    }
    
    // include category for managing duplicates of xp, binutils, fuse, p5-Net-CUPS
    override func key(package pkg: GPackage) -> String {
        if pkg.id != nil {
            return "\(pkg.id)-\(name)"
        } else {
            return "\(pkg.categories!.split()[0])/\(pkg.name)-\(name)"
        }
    }
    
    override func list() -> [GPackage] {
        
        index.removeAll(keepCapacity: true)
        items.removeAll(keepCapacity: true)
        
        var pkgs = [GPackage]()
        pkgs.reserveCapacity(50000)
        var idx = [String: GPackage](minimumCapacity: 50000)
        
        let indexPath = "~/Library/Application Support/Guigna/pkgsrc/INDEX".stringByExpandingTildeInPath
        if NSFileManager.defaultManager().fileExistsAtPath(indexPath) {
            var lines = (NSString(contentsOfFile: indexPath, encoding: NSUTF8StringEncoding, error: nil) as String).split("\n")
            for line in lines {
                let components = line.split("|")
                var name = components[0]
                var sep = name.rindex("-")
                if sep == NSNotFound {
                    continue
                }
                let version = name.substringFromIndex(sep + 1)
                // name = [name substringToIndex:sep];
                let id = components[1]
                sep = id.rindex("/")
                name = id.substringFromIndex(sep + 1)
                let description = components[3]
                let category = components[6]
                let homepage = components[11]
                let pkg = GPackage(name: name, version: version, system: self, status: .Available)
                pkg.id = id
                pkg.categories = category
                pkg.description = description
                pkg.homepage = homepage
                // items += pkg // FIXME: slow
                pkgs += pkg
                // self[name] = pkg // FIXME: slow
                idx[pkg.key] = pkg
            }
            
        } else {
            let url = NSURL(string: "http://ftp.netbsd.org/pub/pkgsrc/current/pkgsrc/README-all.html")
            let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
            var nodes = xmlDoc.rootElement().nodesForXPath("//tr", error: nil) as [NSXMLNode]
            for node in nodes {
                let rowData = node["td"]
                if rowData.count == 0 {
                    continue
                }
                var name = rowData[0].stringValue!
                var sep = name.rindex("-")
                if sep == NSNotFound {
                    continue
                }
                let version = name.substring(sep + 1, name.length - sep - 3)
                name = name.substringToIndex(sep)
                var category = rowData[1].stringValue!
                category = category.substring(1, category.length - 3)
                var description = rowData[2].stringValue!
                sep = description.rindex("  ")
                if sep != NSNotFound {
                    description = description.substringToIndex(sep)
                }
                let pkg = GPackage(name: name, version: version, system: self, status: .Available)
                pkg.categories = category
                pkg.description = description
                let id = "\(category)/\(name)"
                pkg.id = id
                // items += pkg // FIXME: slow
                pkgs += pkg
                // self[name] = pkg // FIXME: slow
                idx[pkg.key] = pkg
            }
        }
        items = pkgs
        index = idx
        self.installed() // update status
        return pkgs
    }
    
    // TODO: outdated()
    override func installed() -> [GPackage] {
        
        if self.isHidden {
            return items.filter { $0.status != .Available} as [GPackage]
        }
        var pkgs = [GPackage]()
        pkgs.reserveCapacity(50000)
        
        if mode == GMode.Online { // workaround otherwise enum value not recognized the first time it is encountered
            return pkgs
        }
        
        var status: GStatus
        for pkg in items as [GPackage] {
            status = pkg.status
            pkg.installed = nil
            if status != .Updated && status != .New {
                pkg.status = .Available
            }
        }
        // [self outdated]; // index outdated ports // TODO
        var outputLines = output(cmd).split("\n")
        var ids = output("\(cmd) -Q PKGPATH -a").split("\n")
        outputLines.removeLast()
        ids.removeLast()
        let whitespaceCharacterSet = NSCharacterSet.whitespaceCharacterSet()
        var i = 0
        for line in outputLines {
            var sep = line.index(" ")
            var name = line.substringToIndex(sep)
            let description = line.substringFromIndex(sep + 1).stringByTrimmingCharactersInSet(whitespaceCharacterSet)
            sep = name.rindex("-")
            let version = name.substringFromIndex(sep + 1)
            // name = [name substringToIndex:sep];
            let id = ids[i]
            sep = id.index("/")
            name = id.substringFromIndex(sep + 1)
            status = .UpToDate
            var pkg: GPackage! = self[id]
            var latestVersion: String = (pkg == nil) ? "" : pkg.version
            if pkg == nil {
                pkg = GPackage(name: name, version: latestVersion, system: self, status: status)
                self[id] = pkg
            } else {
                if pkg.status == .Available {
                    pkg.status = .UpToDate
                }
            }
            pkg.installed = version
            pkg.description = description
            pkg.id = id
            pkgs += pkg
            i++
        }
        return pkgs
    }
    
    // TODO: pkg_info -d
    
    // TODO: pkg_info -B PKGPATH=misc/figlet
    
    override func info(item: GItem) -> String {
        if self.isHidden {
            return super.info(item)
        }
        if mode != .Offline && item.status != .Available {
            return output("\(cmd) \(item.name)")
        } else {
            if item.id != nil {
                return NSString(contentsOfURL: NSURL(string: "http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/\(item.id)/DESCR"), encoding: NSUTF8StringEncoding, error: nil)
            } else { // TODO lowercase (i.e. Hermes -> hermes)
                return NSString(contentsOfURL: NSURL(string: "http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/\(item.categories)/\(item.name)/DESCR"), encoding: NSUTF8StringEncoding, error: nil)
            }
        }
    }
    
    
    override func home(item: GItem) -> String {
        if item.homepage != nil { // already available from INDEX
            return item.homepage
        } else {
            let links = agent.nodes(URL: "http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/\(item.categories)/\(item.name)/README.html", XPath: "//p/a")
            return links[2].attribute("href")
        }
    }
    
    override func log(item: GItem!) -> String {
        if item != nil  {
            if item.id != nil {
                return "http://cvsweb.NetBSD.org/bsdweb.cgi/pkgsrc/\(item.id)/"
            } else {
                return "http://cvsweb.NetBSD.org/bsdweb.cgi/pkgsrc/\(item.categories)/\(item.name)/"
            }
        } else {
            return "http://www.netbsd.org/changes/pkg-changes.html"
        }
    }
    
    override func contents(item: GItem) -> String {
        if item.status != .Available {
            return output("\(cmd) -L \(item.name)").split("Files:\n")[1]
        } else {
            if item.id != nil {
                return NSString(contentsOfURL: NSURL(string: "http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/\(item.id)/PLIST"), encoding: NSUTF8StringEncoding, error: nil)
            } else { // TODO lowercase (i.e. Hermes -> hermes)
                return NSString(contentsOfURL: NSURL(string: "http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/\(item.categories)/\(item.name)/PLIST"), encoding: NSUTF8StringEncoding, error: nil)
            }
        }
    }
    
    override func cat(item: GItem) -> String {
        if item.status != .Available {
            let filtered = items.filter { $0.name == item.name }
            item.id = filtered[0].id
        }
        if item.id != nil {
            return NSString(contentsOfURL: NSURL(string: "http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/\(item.id)/Makefile"), encoding: NSUTF8StringEncoding, error: nil)
        } else { // TODO lowercase (i.e. Hermes -> hermes)
            return NSString(contentsOfURL: NSURL(string: "http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/\(item.categories)/\(item.name)/Makefile"), encoding: NSUTF8StringEncoding, error: nil)
        }
    }
    
    // TODO: Deps: pkg_info -n -r, scrape site, parse Index
    
    override func deps(item: GItem) -> String { // FIXME: "*** PACKAGE MAY NOT BE DELETED *** "
        
        if item.status != .Available {
            let components = output("\(cmd) -n \(item.name)").split("Requires:\n")
            if components.count > 1 {
                return components[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            } else {
                return "[No depends]"
            }
        } else {
            if NSFileManager.defaultManager().fileExistsAtPath("~/Library/Application Support/Guigna/pkgsrc/INDEX".stringByExpandingTildeInPath) {
                // TODO: parse INDEX
                // NSArray *lines = [NSString stringWithContentsOfFile:[@"~/Library/Application Support/Guigna/pkgsrc/INDEX" stringByExpandingTildeInPath] encoding:NSUTF8StringEncoding error:nil];
            }
            return "[Not available]"
        }
    }
    
    override func dependents(item: GItem) -> String {
        if item.status != .Available {
            let components = output("\(cmd) -r \(item.name)").split("required by list:\n")
            if components.count > 1 {
                return components[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            } else {
                return "[No dependents]"
            }
        } else {
            return "[Not available]"
        }
    }
    
    override func installCmd(pkg: GPackage) -> String {
        if pkg.id != nil {
            return "cd /usr/pkgsrc/\(pkg.id) ; sudo /usr/pkg/bin/bmake install clean clean-depends"
        } else {
            return "cd /usr/pkgsrc/\(pkg.categories)/\(pkg.name) ; sudo /usr/pkg/bin/bmake install clean clean-depends"
        }
    }
    
    override func uninstallCmd(pkg: GPackage) -> String {
        return "sudo \(prefix)/sbin/pkg_delete \(pkg.name)"
    }
    
    
    override func cleanCmd(pkg: GPackage) -> String {
        if pkg.id != nil {
            return "cd /usr/pkgsrc/\(pkg.id) ; sudo /usr/pkg/bin/bmake clean clean-depends"
        } else {
            return "cd /usr/pkgsrc/\(pkg.categories)/\(pkg.name) ; sudo /usr/pkg/bin/bmake clean clean-depends"
        }
    }
    
    override var updateCmd: String! {
    get {
        if mode == .Online || agent.appDelegate!.defaults["pkgsrcCVS"] == false {
            return nil
        } else {
            return "sudo cd; cd /usr/pkgsrc ; sudo cvs update -dP"
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
    
    
    class var setupCmd: String! {
        get {
            return "sudo mv /usr/local /usr/local_off ; sudo mv /opt/local /opt/local_off ; sudo mv /sw /sw_off ; cd ~/Library/Application\\ Support/Guigna/pkgsrc ; curl -L -O ftp://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc.tar.gz ; sudo tar -xvzf pkgsrc.tar.gz -C /usr; cd /usr/pkgsrc/bootstrap ; sudo ./bootstrap --compiler clang; sudo mv /usr/local_off /usr/local ; sudo mv /opt/local_off /opt/local ; sudo mv /sw_off /sw"
    }
    }
    
    class var removeCmd: String! {
        get {
            return "sudo rm -r /usr/pkg ; sudo rm -r /usr/pkgsrc ; sudo rm -r /var/db/pkg"
    }
    }
}

