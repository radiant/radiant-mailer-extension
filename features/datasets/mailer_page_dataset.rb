class MailerPageDataset < Dataset::Base
  uses :pages

  def load
    create_page "Contact" do
      create_page_part "contact_body", 
        :name => "body", 
        :content => %Q{
          <r:mailer:form>
            Name:<br/>
            <r:mailer:text name="name" /> <br/>
            Email:<br/>
            <r:mailer:text name="email" /> <br/>
            Message:<br/>
            <r:mailer:textarea name="message" /> <br/>
            <input type="submit" value="Send" />
          </r:mailer:form>}
      create_page_part "mailer",      
        :content => {
            'subject' => 'From the website of Whatever',
            'from' => 'no_reply@aissac.ro',
            'redirect_to' => '/contact/thank-you',
            'recipients' => 'example@aissac.ro'}.to_yaml
      create_page_part "email",
        :content => %Q{
          <r:mailer>
            Name: <r:get name="name" />
            Email: <r:get name="email" />
            Message: <r:get name="message" />
          </r:mailer>
        }
      create_page "Thank You", :body => "Thank you!"
    end
  end
end