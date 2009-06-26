class MailerPageDataset < Dataset::Base
  uses :pages

  def load
    create_page "Mail form" do
      create_page_part "mailer", :content => {'recipients' => 'foo@bar.com', 'from' => 'baz@noreply.com'}.to_yaml
      create_page_part "submit_placeholder", :content => "sending email..."
    end
    create_page "Plain mail" do
      create_page_part "plain_mailer", :content => {'recipients' => 'foo@bar.com', 'from' => 'baz@noreply.com'}.to_yaml, :name => "mailer"
      create_page_part "email", :content => 'The body: <r:mailer:get name="body" />', :name => 'email'
    end
    create_page "HTML mail" do
      create_page_part "html_mailer", :content => {'recipients' => 'foo@bar.com', 'from' => 'baz@noreply.com'}.to_yaml, :name => "mailer"
      create_page_part "email_html", :content => '<html><body><r:mailer:get name="body" /></body></html>'
    end
  end
end