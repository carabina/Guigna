class NSXMLNode
  def nodesForXPath(xpath)
    self.nodesForXPath(xpath, error:nil)
  end
  def [](xpath)
    self.nodesForXPath(xpath, error:nil)
  end
end


class NSXMLElement
  def [](xpath)
    if xpath.start_with?('@')
      return self.attributeForName(xpath[1..-1]).stringValue
    else
      return super
    end
  end
  def href
    self.attributeForName("href").stringValue
  end
end

class NSUserDefaultsController
  def [](key)
    self.values.valueForKey key
  end
  def []=(key, value)
    self.values.setValue(value, forKey:key)
  end
end


class WebView
  def swipeWithEvent(event)
    x = event.deltaX
    if x < 0 && self.canGoForward
      self.goForward
    elsif x > 0 && self.canGoBack
      self.goBack
    end
  end
  def magnifyWithEvent(event)
    multiplier = self.textSizeMultiplier * (event.magnification + 1.0)
    self.setTextSizeMultiplier multiplier
  end
end
