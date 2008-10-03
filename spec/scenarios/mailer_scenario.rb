class MailerScenario < Scenario::Base
  uses :pages

  def load
    create_page "Mail form" do
      create_page_part "mailer", :content => {'recipients' => 'foo@bar.com', 'from' => 'baz@noreply.com'}.to_yaml
    end
    # create_page "Mail plain" do
    #   create_page_part "mailer", :content => {'recipients' => 'foo@bar.com', 'from' => 'baz@noreply.com'}.to_yaml
    #   create_page_part "email", :content => 'The body: <r:mailer:get value="body" />'
    # end
    # create_page "Mail html" do
    #   create_page_part "mailer", :content => {'recipients' => 'foo@bar.com', 'from' => 'baz@noreply.com'}.to_yaml
    #   create_page_part "email_html", :content => '<html><body><r:mailer:get value="body" /></body></html>'
    # end
  end
end