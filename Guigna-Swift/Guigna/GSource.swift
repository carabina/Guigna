import Foundation

enum GState: Int {
    case Off
    case On
    case Hidden
}


enum GMode: Int {
    case Offline
    case Online
}


class GSource: NSObject {
    
    var name: String
    final var categories: [AnyObject]?
    final var items: [GItem]
    var agent: GAgent!
    var mode: GMode
    var status: GState
    var homepage: String!
    var cmd: String!
    
    init(name: String, agent: GAgent?) {
        self.name = name
        self.agent = agent
        items = [GItem]()
        items.reserveCapacity(50000)
        status = .On
        mode = .Offline
    }
    
    convenience init(name: String) {
        self.init(name: name, agent: nil)
    }
    
    func info(item: GItem) -> String {
        return "\(item.name) - \(item.version)\n\(self.home(item))"
    }
    
    func home(item: GItem!) -> String {
        if item?.homepage != nil {
            return item.homepage
        } else {
            return homepage
        }
    }
    
    func log(item: GItem!) -> String {
        return home(item)
    }
    
    func contents(item: GItem!) -> String {
        return ""
    }
    
    func cat(item: GItem!) -> String {
        return "[Not Available]"
    }
    
    
    func deps(item: GItem!) -> String {
        return ""
    }
    
    
    func dependents(item: GItem!) -> String {
        return ""
    }
    
}


@objc(GSourceTransformer)
class GSourceTransformer: NSValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSImage.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(source: AnyObject!) -> AnyObject! {
        if !source {
            return nil
        }
        let name: String = source.name
        switch name {
        case "MacPorts":
            return NSImage(named: "system-macports.tiff")
        case "Homebrew":
            return NSImage(named: "system-homebrew.tiff")
        case "Homebrew Casks":
            return NSImage(named: "system-homebrewcasks.tiff")
        case "Mac OS X":
            return NSImage(named: "system-macosx.tiff")
        case "Fink":
            return NSImage(named: "system-fink.tiff")
        case "pkgsrc":
            return NSImage(named: "system-pkgsrc.tiff")
        case "FreeBSD":
            return NSImage(named: "source-freebsd.tiff")
        case "Rudix":
            return NSImage(named: "system-rudix.tiff")
        case "Native Installers":
            return NSImage(named: "source-native.tiff")
        case "Pkgsrc.se":
            return NSImage(named: "source-pkgsrc.se.tiff")
        case "Debian":
            return NSImage(named: "source-debian.tiff")
        case "PyPI":
            return NSImage(named: "source-pypi.tiff")
        case "RubyGems":
            return NSImage(named: "source-rubygems.tiff")
        case "MacUpdate":
            return NSImage(named: "source-macupdate.tiff")
        case "AppShopper":
            return NSImage(named: "source-appshopper.tiff")
        case "AppShopper iOS":
            return NSImage(named: "source-appshopper.tiff")
        case "installed":
            return NSImage(named: NSImageNameStatusAvailable)
        case "outdated":
            return NSImage(named: NSImageNameStatusPartiallyAvailable)
        case "inactive":
            return NSImage(named: NSImageNameStatusNone)
        case let n where n.hasPrefix("marked"):
            return NSImage(named: "status-marked.tiff")
        case let n where n.hasPrefix("new"):
            return NSImage(named: "status-new.tiff")
        case let n where n.hasPrefix("updated"):
            return NSImage(named: "status-updated.tiff")
        default:
            return nil
        }
    }
}
