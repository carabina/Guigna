import Foundation

class GScrape: GSource {
    var pageNumber: Int
    var itemsPerPage: Int!
    
    init(name: String, agent: GAgent!) {
        pageNumber = 1
        super.init(name: name, agent: agent)
    }
    
    func refresh() {};
}


class PkgsrcSE: GScrape {
    
    init(agent: GAgent) {
        super.init(name: "Pkgsrc.se", agent: agent)
        homepage = "http://pkgsrc.se/"
        itemsPerPage = 25
        cmd = "pkgsrc"
    }
    
    override func refresh() {
        var entries = [GItem]()
        let url = NSURL(string: "http://pkgsrc.se/?page=\(pageNumber)")
        let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
        let mainDiv = xmlDoc.rootElement().nodesForXPath("//div[@id=\"main\"]", error: nil)[0] as NSXMLNode
        var dates = mainDiv["h3"]
        var names = mainDiv["b"]
        names.removeAtIndex(0)
        names.removeAtIndex(0)
        var comments = mainDiv["div"]
        comments.removeAtIndex(0)
        comments.removeAtIndex(0)
        for (i, node) in enumerate(names) {
            let id = node["a"][0].stringValue!
            var idx = id.rindex("/")
            let name = id.substringFromIndex(idx + 1)
            let category = id.substringToIndex(idx)
            var version = dates[i].stringValue!
            idx = version.index(" (")
            if idx != NSNotFound {
                version = version.substringFromIndex(idx + 2)
                version = version.substringToIndex(version.index(")"))
            } else {
                version = version.substringFromIndex(version.rindex(" ") + 1)
            }
            var description = comments[i].stringValue!
            description = description.substringToIndex(description.index("\n"))
            description = description.substringFromIndex(description.index(": ") + 2)
            var entry = GItem(name: name, version: version, source: self, status: .Available)
            entry.id = id
            entry.description = description
            entry.categories = category
            entries += entry
        }
        items = entries
    }
    
    override func home(item: GItem) -> String {
        return agent.nodes(URL: self.log(item), XPath: "//div[@id=\"main\"]//a")[2].attribute("href")
    }
    
    override func log(item: GItem) -> String {
        return "http://pkgsrc.se/\(item.id)"
    }
}


class Debian: GScrape {
    
    init(agent: GAgent) {
        super.init(name: "Debian", agent: agent)
        homepage = "http://packages.debian.org/unstable/"
        itemsPerPage = 100
        cmd = "apt-get"
    }
    
    override func refresh() {
        var pkgs = [GItem]()
        let url = NSURL(string: "http://news.gmane.org/group/gmane.linux.debian.devel.changes.unstable/last=")
        let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
        var nodes = xmlDoc.rootElement().nodesForXPath("//table[@class=\"threads\"]//table/tr", error: nil) as [NSXMLNode]
        for node in nodes {
            let link = node[".//a"][0].stringValue!
            let components = link.split()
            let name = components[1]
            let version = components[2]
            var pkg = GItem(name: name, version: version, source: self, status: .Available)
            pkgs += pkg
        }
        items = pkgs
    }
    
    override func home(item: GItem) -> String {
        var page = log(item)
        let links = agent.nodes(URL: page, XPath: "//a[text()=\"Homepage\"]")
        if links.count > 0 {
            page = links[0].attribute("href")
        }
        return page
    }
    
    override func log(item: GItem) -> String {
        return "http://packages.debian.org/sid/\(item.name)"
    }
}


class PyPI: GScrape {
    
    init(agent: GAgent) {
        super.init(name: "PyPI", agent: agent)
        homepage = "http://pypi.python.org/pypi"
        itemsPerPage = 40
        cmd = "pip"
    }
    
    override func refresh() {
        var eggs = [GItem]()
        let url = NSURL(string: homepage)
        let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
        var nodes = xmlDoc.rootElement().nodesForXPath("//table[@class=\"list\"]//tr", error: nil) as [NSXMLNode]
        nodes.removeAtIndex(0)
        nodes.removeLast()
        for node in nodes {
            let rowData = node["td"]
            let date = rowData[0].stringValue!
            let link = rowData[1]["a"][0].attribute("href")
            let splits = link.split("/")
            let name = splits[splits.count - 2]
            let version = splits[splits.count - 1]
            let description = rowData[2].stringValue!
            var egg = GItem(name: name, version: version, source: self, status: .Available)
            egg.description = description
            eggs += egg
        }
        items = eggs
    }
    
    override func home(item: GItem) -> String {
        return agent.nodes(URL: self.log(item), XPath:"//ul[@class=\"nodot\"]/li/a")[0].stringValue!
        // if nil return [self log:item];
    }
    
    override func log(item: GItem) -> String {
        return "\(self.homepage)/\(item.name)/\(item.version)"
    }
}


class RubyGems: GScrape {
    
    init(agent: GAgent) {
        super.init(name: "RubyGems", agent: agent)
        homepage = "http://rubygems.org/"
        itemsPerPage = 25
        cmd = "gem"
    }
    
    override func refresh() {
        var gems = [GItem]()
        let url = NSURL(string: "http://m.rubygems.org/")
        let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
        let nodes = xmlDoc.rootElement().nodesForXPath("//li", error: nil) as [NSXMLNode]
        for node in nodes {
            let components = node.stringValue!.split()
            let name = components[0]
            let version = components[1]
            let spans = node[".//span"]
            let date = spans[0].stringValue!
            let info = spans[1].stringValue!
            var gem = GItem(name: name, version: version, source: self, status: .Available)
            gem.description = info
            gems += gem
        }
        items = gems
    }
    
    override func home(item: GItem) -> String {
        var page = log(item)
        var links = agent.nodes(URL:page, XPath:"//div[@class=\"links\"]/a")
        if links.count > 0 {
            for link in links {
                if link.stringValue! == "Homepage" {
                    page = link.attribute("href")
                }
            }
        }
        return page
    }
    
    override func log(item: GItem) -> String {
        return "\(self.homepage)gems/\(item.name)"
    }
    
}


class MacUpdate: GScrape {
    
    init(agent: GAgent) {
        super.init(name: "MacUpdate", agent: agent)
        homepage = "http://www.macupdate.com/"
        itemsPerPage = 80
        cmd = "macupdate"
    }
    
    override func refresh() {
        var apps = [GItem]()
        let url = NSURL(string: "https://www.macupdate.com/apps/page/\(pageNumber - 1)")
        let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
        var nodes = xmlDoc.rootElement().nodesForXPath("//div[@class=\"appinfo\"]", error: nil) as [NSXMLNode]
        for node in nodes {
            var name = node["a"][0].stringValue!
            let idx = name.rindex(" ")
            var version = ""
            if idx != NSNotFound {
                version = name.substringFromIndex(idx + 1)
                name = name.substringToIndex(idx)
            }
            let description = node["span"][0].stringValue!.substringFromIndex(2)
            let id = node["a"][0].attribute("href").split("/")[3]
            let app = GItem(name: name, version: version, source: self, status: .Available)
            app.id = id
            app.description = description
            apps += app
        }
        items = apps
    }
    
    override func home(item: GItem) -> String {
        let nodes = agent.nodes(URL: log(item), XPath: "//a[@target=\"devsite\"]")
        let href = nodes[0].attribute("href").stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        return "http://www.macupdate.com\(href)"
    }
    
    override func log(item: GItem) -> String {
        return "http://www.macupdate.com/app/mac/\(item.id)"
    }
}


class AppShopper: GScrape {
    
    init(agent: GAgent) {
        super.init(name: "AppShopper", agent: agent)
        homepage = "http://appshopper.com/mac/all/"
        itemsPerPage = 20
        cmd = "appstore"
    }
    
    
    override func refresh() {
        var apps = [GItem]()
        let url = NSURL(string: "http://appshopper.com/mac/all/\(pageNumber)")
        let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
        var nodes = xmlDoc.rootElement().nodesForXPath("//ul[@class=\"appdetails\"]/li", error: nil) as [NSXMLNode]
        for node in nodes {
            let name = node["h3/a"][0].stringValue!
            var version = node[".//dd"][2].stringValue!
            version = version.substringToIndex(version.length - 1)  // trim final \n
            var id = node["@id"][0].stringValue.substringFromIndex(4)
            let nick = node["a"][0].attribute("href").lastPathComponent
            id += " \(nick)"
            var category = node["div[@class=\"category\"]"][0].stringValue!
            category = category.substringToIndex(category.length - 1) // trim final \n
            let type = node["@class"][0].stringValue!
            var price = node[".//div[@class=\"price\"]"][0].children[0].stringValue!
            let cents = node[".//div[@class=\"price\"]"][0].children[1].stringValue!
            if price == "" {
                price = cents
            } else if !cents.hasPrefix("Buy") {
                price = "\(price).\(cents)"
            }
            // TODO:NSXML UTF8 encoding
            var fixedPrice = price.stringByReplacingOccurrencesOfString("â‚¬", withString: "€")
            var app = GItem(name: name, version: version, source: self, status: .Available)
            app.id = id
            app.categories = category
            app.description = "\(type) \(fixedPrice)"
            apps += app
        }
        items = apps
    }
    
    override func home(item: GItem) -> String {
        let url = NSURL(string: "http://itunes.apple.com/app/id" + item.id.split()[0])
        let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
        let mainDiv = xmlDoc.rootElement().nodesForXPath("//div[@id=\"main\"]", error: nil)[0] as NSXMLNode
        let links = mainDiv["//div[@class=\"app-links\"]/a"]
        let screenshotsImgs = mainDiv["//div[contains(@class, \"screenshots\")]//img"]
        var screenshots = ""
        var i: Int = 0
        for img in screenshotsImgs {
            let url = img.attribute("src")
            if i > 0 {
                screenshots += " "
            }
            screenshots += url
            i++
        }
        item.screenshots = screenshots
        var homepage = links[0].attribute("href")
        if homepage == "http://" {
            homepage = links[1].attribute("href")
        }
        return homepage
    }
    
    override func log(item: GItem) -> String {
        let name = item.id.split()[1]
        var category = item.categories!.stringByReplacingOccurrencesOfString(" ", withString: "-").lowercaseString
        category = category.stringByReplacingOccurrencesOfString("-&-", withString: "-").lowercaseString // fix Healthcare & Fitness
        return "http://www.appshopper.com/mac/\(category)/\(name)"
    }
}


class AppShopperIOS: GScrape {
    
    init(agent: GAgent) {
        super.init(name: "AppShopper iOS", agent: agent)
        homepage = "http://appshopper.com/all/"
        itemsPerPage = 20
        cmd = "appstore"
    }
    
    override func refresh() {
        var apps = [GItem]()
        let url = NSURL(string: "http://appshopper.com/all/\(pageNumber)")
        let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
        var nodes = xmlDoc.rootElement().nodesForXPath("//ul[@class=\"appdetails\"]/li", error: nil) as [NSXMLNode]
        for node in nodes {
            let name = node["h3/a"][0].stringValue!
            var version = node[".//dd"][2].stringValue!
            version = version.substringToIndex(version.length - 1)  // trim final \n
            var id = node["@id"][0].stringValue.substringFromIndex(4)
            let nick = node["a"][0].attribute("href").lastPathComponent
            id += " \(nick)"
            var category = node["div[@class=\"category\"]"][0].stringValue!
            category = category.substringToIndex(category.length - 1) // trim final \n
            let type = node["@class"][0].stringValue!
            var price = node[".//div[@class=\"price\"]"][0].children[0].stringValue!
            let cents = node[".//div[@class=\"price\"]"][0].children[1].stringValue!
            if price == "" {
                price = cents
            } else if !cents.hasPrefix("Buy") {
                price = "\(price).\(cents)"
            }
            // TODO:NSXML UTF8 encoding
            var fixedPrice = price.stringByReplacingOccurrencesOfString("â‚¬", withString: "€")
            var app = GItem(name: name, version: version, source: self, status: .Available)
            app.id = id
            app.categories = category
            app.description = "\(type) \(fixedPrice)"
            apps += app
        }
        items = apps
    }
    
    override func home(item: GItem) -> String {
        let url = NSURL(string: "http://itunes.apple.com/app/id" + item.id.split()[0])
        let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
        let mainDiv = xmlDoc.rootElement().nodesForXPath("//div[@id=\"main\"]", error: nil)[0] as NSXMLNode
        let links = mainDiv["//div[@class=\"app-links\"]/a"]
        let screenshotsImgs = mainDiv["//div[contains(@class, \"screenshots\")]//img"]
        var screenshots = ""
        var i: Int = 0
        for img in screenshotsImgs {
            let url = img.attribute("src")
            if i > 0 {
                screenshots += " "
            }
            screenshots += url
            i++
        }
        item.screenshots = screenshots
        var homepage = links[0].attribute("href")
        if homepage == "http://" {
            homepage = links[1].attribute("href")
        }
        return homepage
    }
    
    override func log(item: GItem) -> String {
        let name = item.id.split()[1]
        var category = item.categories!.stringByReplacingOccurrencesOfString(" ", withString: "-").lowercaseString
        category = category.stringByReplacingOccurrencesOfString("-&-", withString: "-").lowercaseString // fix Healthcare & Fitness
        return "http://www.appshopper.com/mac/\(category)/\(name)"
    }
}
