class String
  def escape_html
    CGI.escapeHTML(self)
  end
end

class Time
  def past?
    self < Time.now
  end
end
