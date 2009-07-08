Given /^the above email has been sent$/ do
  Given "I go to the contact page"
   When "I fill in \"name\" with \"Cristi\""
   When "I fill in \"email\" with \"cristi.duma@aissac.ro\""
   When "I fill in \"message\" with \"Have you heard?\""
   When "I fill in \"attached_file\" with the attachment"
   When "I press \"Send\""
end

When /^I fill in "([^\"]*)" with the attachment$/ do |field|
  fill_in(field, :with => RAILS_ROOT + "/vendor/extensions/mailer/features/fixtures/attachment.txt") 
end

Then /^I should have an attachment$/ do
  current_email.attachments.size.should == 1
end