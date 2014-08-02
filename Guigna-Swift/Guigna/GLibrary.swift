import Foundation

class G {
    
    class func OSVersion() -> String {
        let versionString = NSProcessInfo.processInfo().operatingSystemVersionString
        return versionString.split()[1]
    }
}
