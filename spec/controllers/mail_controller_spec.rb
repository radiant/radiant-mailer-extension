require File.dirname(__FILE__) + '/../spec_helper'

describe MailController do
  dataset :mailer
  describe "POST to /pages/:id/mail" do
    before :each do
      @page = pages(:mail_form)
      @mail = mock("Mail", :send => false)
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.deliveries = []
    end
    
    def do_post
      post :create, :page_id => @page.id, :mailer => {:body => 'Hello, world!'}
    end
    
    it "should load the page by id" do
      do_post
      assigns[:page].should == @page
    end
    
    it "should render the page if mail fails to send" do
      Mail.should_receive(:new).and_return(@mail)
      @mail.should_receive(:send).and_return(false)
      @controller.should_not_receive(:redirect_to)
      do_post
      response.should be_success
      response.body.should == assigns[:page].render
    end
    
    it "should redirect back to the page by default if the mail sends" do
      Mail.should_receive(:new).and_return(@mail)
      @mail.should_receive(:send).and_return(true)
      do_post
      response.should be_redirect
      response.redirect_url.should match(%r{/mail-form/#mail_sent})
    end
    
    it "should redirect to the configured url if the mail sends" do
      @page.part(:mailer).update_attributes(:content => {'redirect_to' => '/first', 'recipients' => 'foo@bar.com', 'from' => 'baz@noreply.com'}.to_yaml)
      Mail.should_receive(:new).and_return(@mail)
      @mail.should_receive(:send).and_return(true)
      do_post
      response.should be_redirect
      response.redirect_url.should match(%r{/first})
    end
  end
end