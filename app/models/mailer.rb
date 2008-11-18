class Mailer < ActionMailer::Base
  def generic_mail(options)
    @recipients = options[:recipients]
    @from = options[:from] || ""
    @cc = options[:cc] || ""
    @bcc = options[:bcc] || ""
    @subject = options[:subject] || ""
    @headers = options[:headers] || {}
    # Not sure that charset works, can see no effect in tests
    @charset = options[:charset] || "utf-8"
    @content_type = "multipart/alternative"
    if options.has_key? :plain_body
      part :content_type => "text/plain", :body => (options[:plain_body] || "")
    end
    if options.has_key? :html_body and !options[:html_body].blank?
      part :content_type => "text/html", :body => (options[:html_body] || "")
    end
  end
end