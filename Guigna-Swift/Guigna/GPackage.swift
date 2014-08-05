import Foundation

class GPackage: GItem {
    
    var options: String!
    var markedOptions: String!
    var repo: String?
    
    init(name: String, version: String, system: GSystem, status: GStatus) {
        super.init(name: name, version: version, source: system, status: status)
        self.system = system
    }
    
    var key: String  {
        get {
            return self.system.key(package: self)
        }
    }
    
    var installCmd: String {
        get {
            return self.system.installCmd(self)
        }
    }
    
    var uninstallCmd: String {
        get {
            return self.system.uninstallCmd(self)
        }
    }
    
    var deactivateCmd: String {
        get {
            return self.system.deactivateCmd(self)
        }
    }
    
    var upgradeCmd: String {
        get {
            return self.system.upgradeCmd(self)
        }
    }
    
    var fetchCmd: String {
        get {
            return self.system.fetchCmd(self)
        }
    }
    
    var cleanCmd: String {
        get {
            return self.system.cleanCmd(self)
        }
    }
}
