class Mailer < ActionMailer::Base
  def generic_mail(options)
    recipients    options[:recipients]
    from          options[:from] || ""
    cc            options[:cc] || ""
    bcc           options[:bcc] || ""
    subject       options[:subject] || ""
    headers       options[:headers] || {}
    content_type  "multipart/mixed"
    charset       options[:charset] || "utf-8"
    
    if options.has_key? :plain_body
      part :content_type => "text/plain", :body => (options[:plain_body] || "")
    end
    if options.has_key? :html_body and !options[:html_body].blank?
      part :content_type => "text/html", :body => (options[:html_body] || "")
    end
    # attchments
    files = options[:files] || []
    limit = options[:filesize_limit] || 0
    files.each do |f|
      if(limit == 0 || f.size <= limit)
        attachment(
          :content_type => "application/octet-stream",
          :body => f.read,
          :filename => f.original_filename)
      else
        raise "The file #{f.original_filename} is too large. The maximum size allowed is #{limit.to_s} bytes."
      end
    end
  end
end