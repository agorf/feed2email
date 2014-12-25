class String
  def escape_html
    CGI.escapeHTML(self)
  end

  def pluralize(count, plural = self + 's')
    "#{count} #{count == 1 ? self : plural}"
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
