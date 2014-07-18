# require 'GAdditions'

class GAgent
  
  # framework 'Foundation'
  
  attr_accessor :app_delegate
  
  def nodes_for_url(url, xpath:xpath)
    page = NSMutableString.alloc.initWithContentsOfURL(NSURL.alloc.initWithString(url), encoding:NSUTF8StringEncoding, error:nil)
    if page.nil?
      page = NSMutableString.alloc.initWithContentsOfURL(NSURL.alloc.initWithString(url), encoding:NSISOLatin1StringEncoding, error:nil)
    end
    data = page.dataUsingEncoding(NSUTF8StringEncoding)
    doc = NSXMLDocument.alloc.initWithData(data, options:NSXMLDocumentTidyHTML, error:nil)
    error = Pointer.new(:object)
    nodes = doc.rootElement.nodesForXPath(xpath, error:error)
    if nodes.empty?
      error[0].description
    else
      nodes
    end
  end
  
end
