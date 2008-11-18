require File.dirname(__FILE__) + '/../spec_helper'

describe "Mailer" do
  before :each do
    ActionMailer::Base.delivery_method = :test
    @deliveries = ActionMailer::Base.deliveries = []
  end
  
  def do_deliver(options={})
    Mailer.deliver_generic_mail({:recipients => ['foo@bar.com'], :plain_body => ''}.merge(options).reject {|k,v| v.nil? })
  end
  
  it "should set the recipients" do
    do_deliver
    @deliveries.first.to.should == ['foo@bar.com']
  end

  it "should be the multipart/alternative content type" do
    do_deliver
    @deliveries.first.content_type.should == 'multipart/alternative'
  end
  
  it "should render a plain body" do
    do_deliver :plain_body => "Hello, world!"
    @deliveries.first.body.should match(/Hello, world!/)
  end
  
  it "should render an HTML body" do
    do_deliver :plain_body => nil, :html_body => "<html><body>Hello, world!</body></html>"
    @deliveries.first.body.should match(%r{<html><body>Hello, world!</body></html>})
  end
  
  it "should render both bodies when present" do
    do_deliver :plain_body => "Hiya!", :html_body => "<html><body>Hello, world!</body></html>"
    @deliveries.first.body.should match(/Hiya!/)
    @deliveries.first.body.should match(%r{<html><body>Hello, world!</body></html>})
  end
  
  it "should set the subject" do
    do_deliver :subject => "Testing 123"
    @deliveries.first.subject.should == "Testing 123"
  end
  
  it "should set the from field" do
    do_deliver :from => "sean@radiant.com"
    @deliveries.first.from.should == %w'sean@radiant.com'
  end
  
  it "should set the cc field" do
    do_deliver :cc => "sean@radiant.com"
    @deliveries.first.cc.should == %w"sean@radiant.com"
  end
  
  it "should set the bcc field" do
    do_deliver :bcc => "sean@radiant.com"
    @deliveries.first.bcc.should == %w"sean@radiant.com"
  end
  
  it "should set the headers" do
    do_deliver :headers => {'Reply-To' => 'sean@cribbs.com'}
    @deliveries.first['Reply-To'].inspect.should match(/sean@cribbs.com/)
  end
  
  # Not sure that charset works, can see no effect in tests
  it "should set the default character set to utf8" do
    pending
    do_deliver
    @deliveries.first.charset.should == 'utf8'
  end
  
  it "should set the character set" do
    pending
    do_deliver :charset => 'iso8859-1'
    @deliveries.first.charset.should == 'iso8859-1'
  end
end