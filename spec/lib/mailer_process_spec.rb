require File.dirname(__FILE__) + "/../spec_helper"
require 'site_controller'
SiteController.class_eval { def rescue_action(e) raise e; end }

describe "MailerProcess" do
  it "should add a last_mail accessor to Page" do
    @page = Page.new
    @page.should respond_to(:last_mail)
    @page.should respond_to(:last_mail=)
  end

  it "should override the process method" do
    @page = Page.new
    @page.should respond_to(:process_without_mailer)
    @page.should respond_to(:process_with_mailer)
  end
end

describe SiteController, "receiving a mailer request", :type => :controller do
  dataset :mailer

  before :each do
    ResponseCache.instance.clear
    Radiant::Config['mailer.post_to_page?'] = true
    @page = pages(:mail_form)
    @mail = mock("Mail", :send => false, :data => {}, :errors => {})
    Page.stub!(:find_by_url).and_return(@page)
    Mail.stub!(:new).and_return(@mail)
  end

  it "should not process a mail form if the request was GET" do
    @page.should_receive(:process_without_mailer).with(request, response)
    Mail.should_not_receive(:new)
    get :show_page, :url => @page.url
  end

  it "should not process a mail form if mailer.post_to_page? is set to false" do
    Radiant::Config['mailer.post_to_page?'] = false
    @page.should_receive(:process_without_mailer).with(request, response)
    Mail.should_not_receive(:new)
    post :show_page, :url => @page.url
  end

  it "should not process a mail form unless there are mailer parameters" do
    @page.should_receive(:process_without_mailer).with(request, response)
    Mail.should_not_receive(:new)
    post :show_page, :url => @page.url
  end

  it "should process a mail form if the request was POST, posting to the page is enabled, and mailer parameters were submitted" do
    Mail.should_receive(:new).and_return(@mail)
    @page.should_receive(:process_without_mailer).with(request, response)
    post :show_page, :url => @page.url, :mailer => {:foo => 'bar'}
  end

  it "should create a Mail object and assign it to the page's last_mail accessor" do
    Mail.should_receive(:new).and_return(@mail)
    @page.should_receive(:last_mail=).with(@mail).at_least(:once)
    post :show_page, :url => @page.url, :mailer => {:foo => 'bar'}
  end

  it "should attempt to send the mail" do
    @mail.should_receive(:send).and_return(false)
    post :show_page, :url => @page.url, :mailer => {:foo => 'bar'}
  end

  it "should clear out the mail data and errors when sending is successful" do
    @mail.should_receive(:send).and_return(true)
    @mail.data.should_receive(:delete_if)
    @mail.errors.should_receive(:delete_if)
    post :show_page, :url => @page.url, :mailer => {:foo => 'bar'}
  end
  
  it "should redirect to the configured URL when sending is successful" do
    @page.should_receive(:mailer_config_and_page).and_return([{:redirect_to => "/foo/bar"}, @page])
    @mail.should_receive(:send).and_return(true)
    post :show_page, :url => @page.url, :mailer => {:foo => 'bar'}
    response.redirect_url.should match(%r{/foo/bar})
  end
end