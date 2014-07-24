import Foundation

class GSystem: GSource {
    var prefix: String
    final var index: [String: GPackage] // declare final to work around the copy of the dictionary
    
    init(name: String, agent: GAgent!) {
        prefix = ""
        index = [String: GPackage](minimumCapacity: 50000)
        super.init(name: name, agent: agent)
        status = .On
    }
    
    func list() -> [GPackage] {
        return []
    }
    
    func installed() -> [GPackage] {
        return []
    }
    
    func outdated() -> [GPackage] {
        return []
    }
    
    func inactive() -> [GPackage] {
        return []
    }
    
    var isHidden: Bool {
    get {
        return NSFileManager.defaultManager().fileExistsAtPath(prefix + "_off")
    }
    }
    
    func key(package pkg: GPackage) -> String {
        return "\(pkg.name)-\(name)"
    }
    
    subscript(name: String) -> GPackage! {
        get {
            return index["\(name)-\(self.name)"]
        }
        set(pkg) {
            index["\(name)-\(self.name)"] = pkg
        }
    }
    
    func categoriesList() -> [String] {
        var categories = NSMutableSet()
        for item in self.items {
            if let cats = item.categories {
                categories.addObjectsFromArray(cats.split())
            }
        }
        var categoriesArray = categories.allObjects as [String]
        categoriesArray.sort { $0 < $1 }
        return categoriesArray
    }
    
    
    func installCmd(pkg: GPackage) -> String {
        return "\(cmd) install \(pkg.name)"
    }
    
    func uninstallCmd(pkg: GPackage) -> String {
        return "\(cmd) uninstall \(pkg.name)"
    }
    
    func deactivateCmd(pkg: GPackage) -> String {
        return "\(cmd) deactivate \(pkg.name)"
    }
    
    func upgradeCmd(pkg: GPackage) -> String {
        return "\(cmd) upgrade \(pkg.name)"
    }
    
    func fetchCmd(pkg: GPackage) -> String {
        return "\(cmd) fetch \(pkg.name)"
    }
    
    func cleanCmd(pkg: GPackage) -> String {
        return "\(cmd) clean \(pkg.name)"
    }
    
    func options(pkg: GPackage) -> String! {
        return nil
    }
    
    
    var updateCmd: String! {
    get  {
        return nil
    }
    }
    
    
    var hideCmd: String! {
    get  {
        return nil
    }
    }
    
    var unhideCmd: String! {
    get  {
        return nil
    }
    }

    func verbosifiedCmd(command: String) -> String {
	    return command.stringByReplacingOccurrencesOfString("\(cmd)", withString: "\(cmd) -d")
	}
    
    func output(command: String) -> String {
        return agent.output(command)
    }
}
