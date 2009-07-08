Feature: Radiant Mailer Extension
  In order to have email sending capabilities
  As an user
  I want to send and receive email

  Scenario: Sending email
    Given I go to the contact page
     When I fill in "name" with "Cristi"
      And I fill in "email" with "cristi.duma@aissac.ro"
      And I fill in "message" with "Have you heard?"
      And I fill in "attached_file" with the attachment
      And I press "Send"
     Then I should be on the thank you page

  Scenario: Receiving email
    Given the above email has been sent
     Then "example@aissac.ro" should receive 1 email
     When I open the email
      And I should see "From the website of Whatever" in the subject
      And I should see "Name: Cristi" in the email
      And I should see "Email: cristi.duma@aissac.ro" in the email
      And I should see "Message: Have you heard?" in the email
      And I should have an attachment