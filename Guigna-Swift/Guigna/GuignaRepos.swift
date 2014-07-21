import Foundation

class GRepo: GScrape {
}


class Native: GRepo {
    init(agent: GAgent) {
        super.init(name: "Native Installers", agent: agent)
        homepage = "http://github.com/gui-dos/Guigna/"
        itemsPerPage = 250
        cmd = "installer"
    }
    
    override var items: [GItem] {
    get {
        var items = [GItem]()
        let url = NSURL(string: "https://docs.google.com/spreadsheet/ccc?key=0AryutUy3rKnHdHp3MFdabGh6aFVnYnpnUi1mY2E2N0E")
        let xmlDoc = NSXMLDocument(contentsOfURL: url, options: Int(NSXMLDocumentTidyHTML), error: nil)
        var nodes = xmlDoc.rootElement().nodesForXPath("//table[@id=\"tblMain\"]//tr", error: nil) as [NSXMLNode]
        for node in nodes {
            if node.attribute("class") != nil { // class is not empty ('rShim')
                continue
            }
            let columns = node["td"]
            let name = columns[1].stringValue!
            let version = columns[2].stringValue!
            let homepage = columns[4].stringValue!
            let url = columns[5].stringValue!
            var item = GItem(name: name, version: version, source: self, status: .Available)
            item.homepage = homepage
            item.description = url
            item.URL = url
            items += item
        }
        return items
    }
    set {}
    }
}


