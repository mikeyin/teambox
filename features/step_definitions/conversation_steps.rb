Given /^the following conversation? with associations exists?:?$/ do |table|
  table.hashes.each do |hash|
    Factory(:conversation,
      :name => hash[:name],
      :user => User.find_by_login(hash[:user]),
      :project => Project.find_by_name(hash[:project])
    )
  end
end

Given /^I started a (p[a-z]+ )?conversation named "([^\"]+)"(?: in the "([^\"]*)" project)?$/ do |priv_type, name, project_name|
  is_private = (priv_type||'').strip == 'private'
  Factory(:conversation, :user => @current_user, :is_private => is_private, :project => (project_name ? Project.find_by_name(project_name) : @current_project), :name => name)
end

Given /^I started a simple conversation(?: in the "([^\"]*)" project)?$/ do |project_name|
  Factory(:conversation, :user => @current_user, :project => (project_name ? Project.find_by_name(project_name) : @current_project), :name => nil, :simple => true)
end

Given /^(@.+) started a (p[a-z]+ )?conversation named "([^\"]+)"(?: in the "([^\"]*)" project)?(?: with an attached (file))?$/ do |user_name, priv_type, conversation_name, project_name, file|
  is_private = (priv_type||'').strip == 'private'
  project = (project_name ? Project.find_by_name(project_name): @current_project)
  user = User.find_by_login(user_name.gsub('@',''))
  conversation = Factory(:conversation, :user => user, :is_private => is_private, :project => project, :name => conversation_name)
  if file
    upload = Factory :upload, :user => user, :project => project, :asset_file_name => "#{is_private ? "Private" : "Normal"} document at #{conversation_name}.png"
    comment = conversation.comments.last
    comment.uploads << upload
    comment.save!
  end
end

Given /^the conversation "([^\"]+)" is watched by (@.+)$/ do |name, users|
  conversation = Conversation.find_by_name(name)
  
  each_user(users) do |user|
    conversation.add_watcher(user)
  end
  
  conversation.save(:validate => false)
end

Given /^(@.+) stops? watching the conversation "([^\"]*)"$/ do |users, name|
  conversation = Conversation.find_by_name(name)
  
  each_user(users) do |user|
    conversation.remove_watcher(user, false)
  end
  
  conversation.save(:validate => false)
end

Then /^(@.+) should( not)? be watching the conversation "([^\"]*)"$/ do |users, negate, name|
  conversation = Conversation.find_by_name(name)
  
  each_user(users) do |user|
    if negate.blank?
      user.should be_watching(conversation)
    else
      user.should_not be_watching(conversation)
    end
  end
end

Then /^(?:|I )should not see any conversations$/ do
  text = "This project doesn't have any conversations yet"

  if Capybara.current_driver == Capybara.javascript_driver
    assert page.has_xpath?(XPath::HTML.content(text), :visible => true)
  elsif page.respond_to? :should
    page.should have_content(text)
  else
    assert page.has_content?(text)
  end
end

When /^(?:|I )fill in the conversation's comment box with "([^\"]*)"(?: within "([^\"]*)")?$/ do |value, selector|
  with_scope(selector) do
    find(:xpath, '//form[contains(@class,"edit_conversation")]//*[@name="comment[body]"]').set(value)
  end
end

When /^(?:|I )fill in the new conversation comment box with "([^\"]*)"?$/ do |value, selector|
  with_scope(selector) do
    find(:xpath, '//form[contains(@class,"new_conversation")]//*[@name="conversation[comments_attributes][0][body]"]').set(value)
  end
end

When /^(?:|I )click the conversation's comment box(?: within "([^\"]*)")?$/ do |selector|
  find("a.expanded_mode").click
  with_scope(selector) do
    find(:xpath, '//form[contains(@class,"edit_conversation")]//*[@name="comment[body]"]').click
  end
end

When /^(?:|I )click the new conversation comment box?$/ do |selector|
  with_scope(selector) do
    find(:xpath, '//form[contains(@class,"new_conversation")]//*[@name="conversation[comments_attributes][0][body]"]').click
  end
end

Then /^I should see the error "([^\"]*)"(?: within "([^\"]*)")?$/ do |msg, selector|
  with_scope(selector) do
    comment = all("span.error").last.text
    comment.should match(/#{msg}/)
  end
end

Then /^I should see "([^\"]+)" in the thread title$/ do |msg|
  link = false
  wait_until do
    link = find("p.thread_title a")
  end
  comment = link.text
  comment.should match(/#{msg}/)
end

Then /^I should see "([^\"]+)" in the page title$/ do |msg|
  header = false
  wait_until do
    header = find("h2")
  end
  title = header.text
  title.should match(/#{msg}/)
end

Then /^I should see "([^\"]+)" in the thread starter$/ do |msg|
  comment = all("p.starter").last.text.strip
  comment.should match(/#{msg}/)
end

When /^I add a comment to the last conversation in the "([^"]*)" project$/ do |project_name|
  project = Project.find_by_name(project_name)
  Factory :comment, :target => project.conversations.last, :user => @current_user
end

