import Foundation

class Fink: GSystem {
    
    init(agent: GAgent) {
        super.init(name: "Fink", agent: agent)
        prefix = "/sw"
        homepage = "http://www.finkproject.org"
        cmd = "\(prefix)/bin/fink"
    }
    
    override func list() -> [GPackage] {
        
        index.removeAll(keepCapacity: true)
        items.removeAll(keepCapacity: true)
        
        if mode == GMode.Online { // FIXME: the compiler requires expilicit enum the first time it is seen
            let url = NSURL(string: "http://pdb.finkproject.org/pdb/browse.php")
            let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
            var nodes = xmlDoc.rootElement().nodesForXPath("//tr[@class=\"package\"]", error: nil) as [NSXMLNode]
            for node in nodes {
                let dataRows = node["td"]
                var description = dataRows[2].stringValue!
                if description.hasPrefix("[virtual") {
                    continue
                }
                let name = dataRows[0].stringValue!
                let version = dataRows[1].stringValue!
                let pkg = GPackage(name: name, version: version, system: self, status: .Available)
                pkg.description = description
                items += pkg
                self[name] = pkg
            }
        } else {
            var outputLines = output("\(cmd) list --tab").split("\n")
            outputLines.removeLast()
            let whitespaceCharacterSet = NSCharacterSet.whitespaceCharacterSet()
            var status: GStatus
            for line in outputLines {
                let components = line.split("\t")
                let description = components[3]
                if description.hasPrefix("[virtual") {
                    continue
                }
                let name = components[1]
                let version = components[2]
                let state = components[0].stringByTrimmingCharactersInSet(whitespaceCharacterSet)
                status = .Available
                if state == "i" || state == "p" {
                    status = .UpToDate
                }
                else if state == "(i)" {
                    status = .Outdated
                }
                let pkg = GPackage(name: name, version: version, system: self, status: status)
                pkg.description = description
                items += pkg
                self[name] = pkg
            }
        }
        self.installed() // update status
        return items as [GPackage]
    }
    
    
    override func installed() -> [GPackage] {
        
        if self.isHidden {
            return items.filter { $0.status != .Available} as [GPackage]
        }
        var pkgs = [GPackage]()
        pkgs.reserveCapacity(50000)
        
        if mode == .Online {
            return pkgs
        }
        
        var status: GStatus
        for pkg in items as [GPackage] {
            status = pkg.status
            pkg.installed = nil
            if status != .Updated && status != .New { // TODO: !pkg.description.hasPrefix("[virtual")
                pkg.status = .Available
            }
        }
        var outputLines = output("\(prefix)/bin/dpkg-query --show").split("\n")
        outputLines.removeLast()
        for line in outputLines {
            let components = line.split("\t")
            let name = components[0]
            let version = components[1]
            status = .UpToDate
            var pkg: GPackage! = self[name]
            var latestVersion: String = (pkg == nil) ? "" : pkg.version
            if pkg == nil {
                pkg = GPackage(name: name, version: latestVersion, system: self, status: status)
                self[name] = pkg
            } else {
                if pkg.status == .Available {
                    pkg.status = .UpToDate
                }
            }
            pkg.installed = version
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
        
        var outputLines = output("\(cmd) list --outdated --tab").split("\n")
        outputLines.removeLast()
        for line in outputLines {
            let components = line.split("\t")
            let name = components[1]
            let version = components[2]
            let description = components[3]
            var pkg: GPackage! = self[name]
            var latestVersion: String = (pkg == nil) ? "" : pkg.version
            if pkg == nil {
                pkg = GPackage(name: name, version: latestVersion, system: self, status: .Outdated)
                self[name] = pkg
            } else {
                pkg.status = .Outdated
            }
            pkg.description = description
            pkgs += pkg
        }
        return pkgs
    }
    
    // TODO: pkg_info -d
    
    // TODO: pkg_info -B PKGPATH=misc/figlet
    
    override func info(item: GItem) -> String {
        if self.isHidden {
            return super.info(item)
        }
        if mode == .Online {
            let nodes = agent.nodes(URL: "http://pdb.finkproject.org/pdb/package.php/\(item.name)", XPath: "//div[@class=\"desc\"]")
            if nodes.count == 0 {
                return "[Info not available]"
            } else {
                return nodes[0].stringValue!
            }
        } else {
            return output("\(cmd) dumpinfo \(item.name)")
        }
        
    }
    
    
    override func home(item: GItem) -> String {
        let nodes = agent.nodes(URL: "http://pdb.finkproject.org/pdb/package.php/\(item.name)", XPath: "//a[contains(@title, \"home\")]")
        if nodes.count == 0 {
            return "[Homepage not available]"
        } else {
            return nodes[0].stringValue!
        }
    }
    
    override func log(item: GItem!) -> String {
        if item != nil {
            return "http://pdb.finkproject.org/pdb/package.php/\(item.name)"
        } else {
            return "http://www.finkproject.org/package-updates.php"
            // @"http://github.com/fink/fink/commits/master"
        }
    }
    
    override func contents(item: GItem) -> String {
        return ""
    }
    
    override func cat(item: GItem) -> String {
        if item.status != .Available || mode == .Online {
            let nodes = agent.nodes(URL: "http://pdb.finkproject.org/pdb/package.php/\(item.name)", XPath: "//a[contains(@title, \"info\")]")
            if nodes.count == 0 {
                return "[.info not reachable]"
            } else {
                let cvs = nodes[0].stringValue!
                let info = NSString(contentsOfURL: NSURL(string: "http://fink.cvs.sourceforge.net/fink/\(cvs)"), encoding: NSUTF8StringEncoding, error: nil)
                return info
            }
        } else {
            return output("\(cmd) dumpinfo \(item.name)")
        }
    }
    
    
    // TODO: Deps
    
    override func installCmd(pkg: GPackage) -> String {
        return "sudo \(cmd) install \(pkg.name)"
        
    }
    
    override func uninstallCmd(pkg: GPackage) -> String {
        return "sudo \(cmd) remove \(pkg.name)"
    }
    
    override func upgradeCmd(pkg: GPackage) -> String {
        return "sudo \(cmd) update \(pkg.name)"
    }
    
    
    override var updateCmd: String! {
    get {
        if mode == .Online {
            return nil
        } else {
            return "sudo \(cmd) selfupdate"
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
            return "sudo mv /usr/local /usr/local_off ; sudo mv /opt/local /opt/local_off ; sudo mv /usr/pkg /usr/pkg_off ; cd ~/Library/Application\\ Support/Guigna/Fink ; curl -L -O http://downloads.sourceforge.net/fink/fink-0.37.0.tar.gz ; tar -xvzf fink-0.37.0.tar.gz ; cd fink-0.37.0 ; sudo ./bootstrap ; /sw/bin/pathsetup.sh ; . /sw/bin/init.sh ; /sw/bin/fink selfupdate-rsync ; /sw/bin/fink index -f ; sudo mv /usr/local_off /usr/local ; sudo mv /opt/local_off /opt/local ; sudo mv /usr/pkg_off /usr/pkg"
    }
    }
    
    class var removeCmd: String! {
        get {
            return "sudo rm -rf /sw"
    }
    }
    
    override func verbosifiedCmd(command: String) -> String  {
        return cmd.stringByReplacingOccurrencesOfString(cmd, withString: "\(cmd) -v")
    }
}

