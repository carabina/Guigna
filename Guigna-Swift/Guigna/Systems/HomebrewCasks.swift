import Foundation

class HomebrewCasks: GSystem {
    
    class func prefix() -> String { // class vars not yet supported
        return "/usr/local"
    }
    
    init(agent: GAgent) {
        super.init(name: "Homebrew Casks", agent: agent)
        prefix = "/usr/local"
        homepage = "http://caskroom.io"
        cmd = "\(prefix)/bin/brew cask"
    }
    
    override func list() -> [GPackage] {
        
        index.removeAll(keepCapacity: true)
        items.removeAll(keepCapacity: true)
        
        var outputLines = output("/bin/sh -c /usr/bin/grep__\"version__'\"__-r__/\(prefix)/Library/Taps/caskroom/homebrew-cask/Casks").split("\n")
        outputLines.removeLast()
        let whitespaceCharacterSet = NSCharacterSet.whitespaceCharacterSet()
        for line in outputLines {
            let components = line.stringByTrimmingCharactersInSet(whitespaceCharacterSet).split()
            var name = components[0].lastPathComponent
            name = name.substringToIndex(name.length - 4)
            var version = components[components.count - 1]
            version = version.substring(1, version.length - 2)
            var pkg = GPackage(name: name, version: version, system: self, status: .Available)
            // avoid duplicate entries (i.e. aquamacs, opensesame)
            if self[pkg.name] != nil {
                let prevPackage = self[pkg.name]
                var found: Int?
                for (i, pkg) in enumerate(items) {
                    if pkg.name == name {
                        found = i
                        break
                    }
                }
                if let idx = found {
                    items.removeAtIndex(idx)
                }
                if prevPackage!.version > version {
                    pkg = prevPackage!
                }
            }
            items += pkg
            self[name] = pkg
        }
        self.installed() // update status
        return items as [GPackage]
    }
    
    // TODO: port from Homebrew
    
    override func installed() -> [GPackage] {
        
        if self.isHidden {
            return items.filter { $0.status != .Available} as [GPackage]
        }
        
        var pkgs = [GPackage]()
        pkgs.reserveCapacity(50000)
        
        if mode == GMode.Online { // workaround otherwise enum value not recognized the first time it is encountered
            return pkgs
        }
        
        let escapedCmd = cmd.stringByReplacingOccurrencesOfString(" ", withString: "__")
        var outputLines = output("/bin/sh -c export__PATH=\(prefix)/bin:$PATH__;__\(escapedCmd)__list__2>/dev/null").split("\n")
        outputLines.removeLast()
        var status: GStatus
        
        // TODO: remove inactive packages from items and allPackages

        for pkg in items as [GPackage] {
            status = pkg.status
            pkg.installed = nil
            if status != .Updated && status != .New {
                pkg.status = .Available
            }
        }
        // self.outdated() // update status
        for line in outputLines {
            let name = line
            if name == "Error:" {
                return pkgs
            }
            var version = output("/bin/ls /opt/homebrew-cask/Caskroom/\(name)").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            // TODO: manage multiple versions
            version = version.stringByReplacingOccurrencesOfString("\n", withString: ", ")
            var pkg: GPackage! = self[name]
            var latestVersion: String = (pkg == nil) ? "" : pkg.version
            if pkg == nil {
                pkg = GPackage(name: name, version: latestVersion, system: self, status: .UpToDate)
                self[name] = pkg
            } else {
                if pkg.status == .Available {
                    pkg.status = .UpToDate
                }
            }
            pkg.installed = version // TODO
            if latestVersion != nil {
                if !version.hasSuffix(latestVersion) {
                    pkg.status = .Outdated
                }
            }
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
        
        for pkg in installed() {
            if pkg.status == .Outdated {
                pkgs += pkg
            }
        }
        return pkgs
        
    }
    
    
    override func info(item: GItem) -> String {
        let escapedCmd = cmd.stringByReplacingOccurrencesOfString(" ", withString: "__")
        if !self.isHidden {
            return output("/bin/sh -c export__PATH=\(prefix)/bin:$PATH__;__\(escapedCmd)__info__\(item.name)")
        } else {
            return super.info(item)
        }
    }
    
    override func home(item: GItem) -> String {
        let escapedCmd = cmd.stringByReplacingOccurrencesOfString(" ", withString: "__")
        if self.isHidden {
            var homepage = ""
            for line in cat(item).split("\n") {
                let loc = (line as NSString).rangeOfString("homepage").location
                if loc != NSNotFound {
                    homepage = line.substringFromIndex(loc + 8).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    if homepage.contains("http") {
                        return homepage.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "'\""))
                    }
                }
            }
        } else {
            if !self.isHidden && (item as GPackage).repo == nil {
                return output("/bin/sh -c export__PATH=\(prefix)/bin:$PATH__;__\(escapedCmd)__info__\(item.name)").split("\n")[1]
            }
        }
        return log(item)
    }
    
    override func log(item: GItem!) -> String {
        if item != nil {
            var path = ""
            if (item as GPackage).repo == nil {
                path = "caskroom/homebrew-cask/commits/master/Casks"
                //            } else {
                //                let tokens = (item as GPackage).repo!.split("/")
                //                let user = tokens[0]
                //                path = "\(user)/homebrew-\(tokens[1])/commits/master"
            }
            return "http://github.com/\(path)/\(item.name).rb"
        } else {
            return "http://github.com/caskroom/homebrew-cask/commits"
        }
    }
    
    override func contents(item: GItem) -> String {
        let escapedCmd = cmd.stringByReplacingOccurrencesOfString(" ", withString: "__")
        if !self.isHidden {
            return output("/bin/sh -c export__PATH=\(prefix)/bin:$PATH__;__\(escapedCmd)__list__\(item.name)")
        } else {
            return ""
        }
    }
    
    override func cat(item: GItem) -> String {
        let escapedCmd = cmd.stringByReplacingOccurrencesOfString(" ", withString: "__")
        if !self.isHidden {
            return output("/bin/sh -c export__PATH=\(prefix)/bin:$PATH__;__\(escapedCmd)__cat__\(item.name)")
        } else {
            return NSString(contentsOfFile: "\(prefix)_off/Library/Taps/caskroom/homebrew-cask/Casks/\(item.name).rb", encoding: NSUTF8StringEncoding, error: nil)
        }
    }
    
    override func deps(item: GItem) -> String {
        return ""
    }
    
    override func dependents(item: GItem) -> String {
        return ""
    }
    
    
    override func installCmd(pkg: GPackage) -> String {
        var options: String? = pkg.markedOptions
        if options == nil {
            options = ""
        } else {
            options = "--" + options!.stringByReplacingOccurrencesOfString(" ", withString: " --")
        }
        return "\(cmd) install \(options) \(pkg.name)"
    }
    
    
    override func uninstallCmd(pkg: GPackage) -> String {
        return "\(cmd) uninstall \(pkg.name)"
    }
    
    // FIXME: not possible currently
    override func upgradeCmd(pkg: GPackage) -> String {
        return "\(cmd) uninstall \(pkg.name) ; \(cmd) install \(pkg.name)"
    }
    
    override func cleanCmd(pkg: GPackage) -> String {
        return "\(cmd) cleanup --force \(pkg.name) &>/dev/null"
    }
    
    //    override var updateCmd: String! {
    //    get {
    //        return "\(cmd) update"
    //    }
    //    }
    
    override var hideCmd: String! {
    get {
        return "sudo mv \(prefix) \(prefix)_off"
    }
    }
    
    override var unhideCmd: String! {
    get {
        return "sudo mv \(prefix)_off \(prefix)"
    }
    }
    
    // TODO: class vars  not yet supported
    
    class var setupCmd: String! {
        get {
            return "\(prefix())/bin/brew install caskroom/cask/brew-cask ; \(prefix())/bin/brew cask list"
    }
    }
    
    class var removeCmd: String! {
        get {
            return "\(prefix())/bin/brew untap caskroom/cask"
    }
    }
    
    override func verbosifiedCmd(command: String) -> String {
        var tokens = command.split()
        tokens.insert("-v", atIndex: 2)
        return tokens.join()
    }
    
}

