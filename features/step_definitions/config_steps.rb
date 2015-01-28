Given /^an empty config file with mode "([^"]*)"$/ do |file_mode|
  step "an empty file named \"#{Feed2Email.config_path}\" with mode \"#{file_mode}\""
end

Given /^a config file with mode "([^"]*)" and with:$/ do |file_mode, file_content|
  step "a file named \"#{Feed2Email.config_path}\" with mode \"#{file_mode}\" and with:", file_content
end
