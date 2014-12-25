class String
  def self.pluralize(count, singular, plural = singular + 's')
    "#{count} #{count == 1 ? singular : plural}"
  end

  def escape_html
    CGI.escapeHTML(self)
  end

  def strip_html
    CGI.unescapeHTML(Sanitize.clean(self))
  end
end

class Time
  def past?
    self < Time.now
  end
end
