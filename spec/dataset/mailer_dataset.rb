class MailerDataset < Dataset::Base
  uses :pages

  def load
    create_page "Mail form" do
      create_page_part "mailer", :content => {'recipients' => 'foo@bar.com', 'from' => 'baz@noreply.com'}.to_yaml
    end
    create_page "Plain mail" do
      create_page_part "plain_mailer", :content => {'recipients' => 'foo@bar.com', 'from' => 'baz@noreply.com'}.to_yaml, :name => "mailer"
      create_page_part "email_plain", :content => 'The body: <r:mailer:get name="body" />', :name => 'email'
    end
    create_page "HTML mail" do
      create_page_part "html_mailer", :content => {'recipients' => 'foo@bar.com', 'from' => 'baz@noreply.com'}.to_yaml, :page_id => page_id(:html_mail), :name => "mailer"
      create_page_part "email_html", :content => '<html><body><r:mailer:get name="body" /></body></html>', :page_id => page_id(:html_mail)
    end
  end
end