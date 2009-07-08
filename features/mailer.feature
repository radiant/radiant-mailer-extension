Feature: Mailer
  In order to value
  As a role
  I want feature

  Scenario: Test
    Given I go to the contact page
     When I fill in "name" with "Cristi"
      And I fill in "email" with "cristi.duma@aissac.ro"
      And I fill in "message" with "test"
      And I press "Send"
     Then "foo@bar.com" should receive 1 email
     When I open the email
      And I should see "Email from my Radiant site!" in the subject
      And I should see "Cristi" in the email
      And I should see "cristi.duma@aissac.ro" in the email
      And I should see "test" in the email