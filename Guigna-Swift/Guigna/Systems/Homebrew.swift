import Foundation

class Homebrew: GSystem {
    
    init(agent: GAgent) {
        super.init(name: "Homebrew", agent: agent)
        prefix = "/usr/local"
        homepage = "http://brew.sh/"
        cmd = "\(prefix)/bin/brew"
    }
    
    override func list() -> [GPackage] {
        
        index.removeAll(keepCapacity: true)
        items.removeAll(keepCapacity: true)
        
        var pkgs = [GPackage]()
        pkgs.reserveCapacity(50000)
        var idx = [String: GPackage](minimumCapacity: 50000)
        
        // /usr/bin/ruby -C /usr/local/Library/Homebrew -I. -e "require 'global'; require 'formula'; Formula.each {|f| puts \"#{f.name} #{f.pkg_version}\"}"
        
        var outputLines = output("/usr/bin/ruby -C \(prefix)/Library/Homebrew -I. -e require__'global';require__'formula';__Formula.each__{|f|__puts__\"#{f.name}__#{f.pkg_version}__#{f.bottle}\"}").split("\n")
        outputLines.removeLast()
        for line in outputLines {
            let components = line.split()
            let name = components[0]
            let version = components[1]
            let bottle = components[2]
            let pkg = GPackage(name: name, version: version, system: self, status: .Available)
            if bottle != "" {
                pkg.description = "Bottle"
            }
            // items += pkg // FIXME: slow
            pkgs += pkg
            // self[name] = pkg // FIXME: slow
            idx[pkg.key] = pkg
        }
        // TODO HomebrewMainTaps
        items = pkgs
        index = idx
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
        
        var outputLines = output("\(cmd) list --versions").split("\n")
        outputLines.removeLast()
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
        self.outdated() // update status
        for line in outputLines {
            var components = line.split()
            let name = components[0]
            if name == "Error:" {
                return pkgs
            }
            components.removeAtIndex(0)
            let versionCount = components.count
            let version = components[components.count - 1]
            var pkg: GPackage! = self[name]
            var latestVersion: String = (pkg == nil) ? "" : pkg.version
            if versionCount > 1 {
                for var i = 0 ; i < versionCount - 1 ; i++ {
                    var inactivePkg = GPackage(name: name, version: latestVersion, system: self, status: .Inactive)
                    inactivePkg.installed = components[i]
                    items += inactivePkg
                    self.agent.appDelegate!.addItem(inactivePkg) // TODO: ugly
                    pkgs += inactivePkg
                }
            }
            if pkg == nil {
                pkg = GPackage(name: name, version: latestVersion, system: self, status: .UpToDate)
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
        
        var outputLines = output("\(cmd) outdated").split("\n")
        outputLines.removeLast()
        for line in outputLines {
            let components = line.split()
            let name = components[0]
            if name == "Error:" {
                return pkgs
            }
            var pkg = self[name]
            var latestVersion: String = (pkg == nil) ? "" : pkg.version
            // let version = components[1] // TODO: strangely, output contains only name
            let version = (pkg == nil) ? "..." : pkg.installed
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
        if !self.isHidden {
            return output("\(cmd) info \(item.name)")
        } else {
            return super.info(item)
        }
    }
    
    override func home(item: GItem) -> String {
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
                return output("\(cmd) info \(item.name)").split("\n")[1]
            }
        }
        return log(item)
    }
    
    override func log(item: GItem!) -> String {
        if item != nil {
            var path: String
            if (item as GPackage).repo == nil {
                path = "Homebrew/homebrew/commits/master/Library/Formula"
            } else {
                let tokens = (item as GPackage).repo!.split("/")
                let user = tokens[0]
                path = "\(user)/homebrew-\(tokens[1])/commits/master"
            }
            return "http://github.com/\(path)/\(item.name).rb"
        } else {
            return "http://github.com/Homebrew/homebrew/commits"
        }
    }
    
    override func contents(item: GItem) -> String {
        if !self.isHidden {
            return output("\(cmd) list -v \(item.name)")
        } else {
            return ""
        }
    }
    
    override func cat(item: GItem) -> String {
        if !self.isHidden {
            return output("\(cmd) cat \(item.name)")
        } else {
            return NSString(contentsOfFile: "\(prefix)_off/Library/Formula/\(item.name).rb", encoding: NSUTF8StringEncoding, error: nil)
        }
    }
    
    override func deps(item: GItem) -> String {
        if !self.isHidden {
            return output("\(cmd) deps -n \(item.name)")
        } else {
            return "[Cannot compute the dependencies now]"
        }
    }
    
    override func dependents(item: GItem) -> String {
        if !self.isHidden {
            return output("\(cmd) uses --installed \(item.name)")
        } else {
            return ""
        }
    }
    
    override func options(pkg: GPackage) -> String! {
        var options: String! = nil
        var outputLines = output("\(cmd) options \(pkg.name)").split("\n")
        if outputLines.count > 1  {
            let optionLines = outputLines.filter { $0.hasPrefix("--") }
            options = optionLines.join().stringByReplacingOccurrencesOfString("--", withString: "")
        }
        return options
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
        if pkg.status == .Inactive {
            return self.cleanCmd(pkg)
        } else { // TODO: manage --force flag
            return "\(cmd) remove --force \(pkg.name)"
        }
    }
    
    override func upgradeCmd(pkg: GPackage) -> String {
        return "\(cmd) upgrade \(pkg.name)"
    }
    
    
    override func cleanCmd(pkg: GPackage) -> String {
        return "\(cmd) cleanup --force \(pkg.name) &>/dev/null ; rm -f /Library/Caches/Homebrew/\(pkg.name)-\(pkg.version)*bottle*"
    }
    
    
    override var updateCmd: String! {
    get {
        return "\(cmd) update"
    }
    }
    
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
    
    class var setupCmd: String! {
        get {
            return "ruby -e \"$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)\" ; /usr/local/bin/brew update"
    }
    }
    
    class var removeCmd: String! {
        get {
            return "cd /usr/local ; curl -L https://raw.github.com/gist/1173223 -o uninstall_homebrew.sh; sudo sh uninstall_homebrew.sh ; rm uninstall_homebrew.sh ; sudo rm -rf /Library/Caches/Homebrew; rm -rf /usr/local/.git"
    }
    }
    
    override func verbosifiedCmd(command: String) -> String {
        var tokens = command.split()
        tokens.insert("-v", atIndex: 2)
        return tokens.join()
    }
    
}

