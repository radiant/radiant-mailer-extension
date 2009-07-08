class MailerPageDataset < Dataset::Base
  uses :pages

  def load
    create_page "Mail form" do
      create_page_part "mailer_form_body", 
          :name => "body", 
          :content => %Q{
            <r:mailer:form>
              <r:mailer:hidden name="subject" value="Email from my Radiant site!" /> <br/>
              Name:<br/>
              <r:mailer:text name="name" /> <br/>
              Email:<br/>
              <r:mailer:text name="email" /> <br/>
              Message:<br/>
              <r:mailer:textarea name="message" /> <br/>
              <input type="submit" value="Send" />
            </r:mailer:form>}
      create_page_part "mailer", :content => {'recipients' => 'foo@bar.com', 'from' => 'baz@noreply.com'}.to_yaml
      create_page_part "submit_placeholder", :content => "sending email..."
    end
  end
end