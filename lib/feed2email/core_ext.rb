class String
  def escape_html
    CGI.escapeHTML(self)
  end
end
