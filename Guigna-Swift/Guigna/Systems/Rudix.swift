import Foundation

class Rudix: GSystem {
    
    init(agent: GAgent) {
        super.init(name: "Rudix", agent: agent)
        prefix = "/usr/local"
        homepage = "http://rudix.org/"
        cmd = "\(prefix)/bin/rudix"
    }
    
    func clampedOSVersion() -> String {
        var osVersion = G.OSVersion()
        if osVersion < "10.6" || osVersion > "10.9" {
            osVersion = "10.9"
        }
        return osVersion
    }
    
    override func list() -> [GPackage] {
        
        index.removeAll(keepCapacity: true)
        items.removeAll(keepCapacity: true)
        
        var command = "\(cmd) search"
        var osxVersion = clampedOSVersion()
        if G.OSVersion() != osxVersion {
            command = "/bin/sh -c export__OSX_VERSION=\(osxVersion)__;__\(cmd)__search"
        }
        var outputLines = output(command).split("\n")
        outputLines.removeLast()
        for line in outputLines {
            var components = line.split("-")
            var name = components[0]
            if components.count == 4 {
                name += "-\(components[1])"
                components.removeAtIndex(1)
            }
            var version = components[1]
            version += "-" + components[2].split(".")[0]
            let pkg = GPackage(name: name, version: version, system: self, status: .Available)
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
            }
            items += pkg
            self[name] = pkg
        }
        self.installed() // update status
        return items as [GPackage]
    }
    
    
    override func home(item: GItem!) -> String {
        return "http://rudix.org/packages/\(item.name).html"
    }
    
    
    override func log(item: GItem!) -> String {
        if item != nil {
            return "https://github.com/rudix-mac/rudix/commits/master/Ports/\(item.name)"
        } else {
            return "https://github.com/rudix-mac/rudix/commits"
        }
    }
    
    
    override func installCmd(pkg: GPackage) -> String {
        var command = "\(cmd) install \(pkg.name)"
        let osxVersion = clampedOSVersion()
        if G.OSVersion() != osxVersion {
            command = "OSX_VERSION=\(osxVersion) \(command)"
        }
        return "sudo \(command)"
    }
    
    override func uninstallCmd(pkg: GPackage) -> String {
        return "sudo \(cmd) remove \(pkg.name)"
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
            return "curl -s https://raw.githubusercontent.com/rudix-mac/rpm/master/rudix.py | sudo python - install rudix"
    }
    }
}

