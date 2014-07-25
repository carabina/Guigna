import Foundation

enum GStatus: Int {
    case Available = 0
    case Inactive
    case UpToDate
    case Outdated
    case Updated
    case New
    case Broken
}

enum GMark: Int {
    case NoMark = 0
    case Install
    case Uninstall
    case Deactivate
    case Upgrade
    case Fetch
    case Clean
}


class GItem: NSObject {
    var name: String
    var version: String
    weak var source: GSource!
    weak var system: GSystem!
    
    var status: GStatus {
    willSet(newValue) {
        self.willChangeValueForKey("statusValue")
    }
    didSet(newValue) {
        self.didChangeValueForKey("statusValue")
    }
    }
    var statusValue: NSNumber {
    get {
        return NSNumber.numberWithInteger(self.status.toRaw())
    }
    set {
        status = GStatus.fromRaw(newValue.integerValue)!
    }
    }
    
    var mark: GMark {
    willSet(newValue) {
        self.willChangeValueForKey("markValue")
    }
    didSet(newValue) {
        self.didChangeValueForKey("markValue")
    }
    }
    var markValue: NSNumber {
    get {
        return NSNumber.numberWithInteger(self.mark.toRaw())
    }
    set {
        mark = GMark.fromRaw(newValue.integerValue)!
    }
    }
    
    var installed: String!
    var categories: String?
    var _description: String?
    override var description: String {
    get {
        if _description {
            return _description!
        } else {
            return ""
        }
    }
    set {
        self._description = newValue}
    }
    var homepage: String!
    var screenshots: String!
    var URL: String!
    var license: String?
    var id: String!
    
    init(name: String, version: String, source: GSource, status: GStatus) {
        self.name = name
        self.version = version
        self.source = source
        self.system = nil
        self.status = status
        self.mark = .NoMark
    }
    
    var info: String {
    get {
        return source.info(self)
    }
    }
    
    var home: String {
    get {
        return source.home(self)
    }
    }
    
    var log: String {
    get {
        return source.log(self)
    }
    }
    
    var contents: String {
    get {
        return source.contents(self)
    }
    }
    
    var cat: String {
    get {
        return source.cat(self)
    }
    }
    
    var deps: String {
    get {
        return source.deps(self)
    }
    }
    
    var dependents: String {
    get {
        return source.dependents(self)
    }
    }
}


@objc(GStatusTransformer)
class GStatusTransformer: NSValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSImage.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(value: AnyObject!) -> AnyObject! {
        if !value {
            return nil
        }
        let status = GStatus.fromRaw(value.integerValue)!
        switch status {
        case .Inactive:
            return NSImage(named: NSImageNameStatusNone)
        case .UpToDate:
            return NSImage(named: NSImageNameStatusAvailable)
        case .Outdated:
            return NSImage(named: NSImageNameStatusPartiallyAvailable)
        case .Updated:
            return NSImage(named: "status-updated.tiff")
        case .New:
            return NSImage(named: "status-new.tiff")
        case .Broken:
            return NSImage(named: NSImageNameStatusUnavailable)
        default:
            return nil
        }
    }
}


@objc(GMarkTransformer)
class GMarkTransformer: NSValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSImage.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(value: AnyObject!) -> AnyObject! {
        if !value  {
            return nil
        }
        let mark = GMark.fromRaw(value.integerValue)!
        switch mark {
        case .Install:
            return NSImage(named: NSImageNameAddTemplate)
        case .Uninstall:
            return NSImage(named: NSImageNameRemoveTemplate)
        case .Deactivate:
            return NSImage(named: NSImageNameStopProgressTemplate)
        case .Upgrade:
            return NSImage(named: NSImageNameRefreshTemplate)
        case .Fetch:
            return NSImage(named: "source-native.tiff")
        case .Clean:
            return NSImage(named: NSImageNameActionTemplate)
        default:
            return nil
        }
    }
}


