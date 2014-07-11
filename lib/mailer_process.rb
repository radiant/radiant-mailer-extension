module MailerProcess
  def self.included(base)
    base.class_eval {
      unless self.instance_methods(false).include?(:process_without_mailer)
        alias_method_chain :process, :mailer
      end
      attr_accessor :last_mail
    }
  end

  def process_with_mailer(request, response)
    # If configured to do so, receive and process the mailer POST
    if Radiant::Config['mailer.post_to_page?'] && request.post? && request.parameters[:mailer]
      config, part_page = mailer_config_and_page

      mail = Mail.new(part_page, config, request.parameters[:mailer])
      self.last_mail = part_page.last_mail = mail
      process_mail(mail, config)

      if mail.send
        response.redirect(config[:redirect_to], "302 Found") and return if config[:redirect_to]
        # Clear out the data and errors so the form isn't populated, but keep the success status around.
        self.last_mail.data.delete_if { true }
        self.last_mail.errors.delete_if { true }
      end
    end
    process_without_mailer(request, response)
  end

  private
  
    # Hook here to do additional things, like check a CAPTCHA
    def process_mail(mail, config)
    end
    
    def mailer_config_and_page
      page = self
      until page.part(:mailer) or (not page.parent)
        page = page.parent
      end
      string = page.render_part(:mailer)
      [(string.empty? ? {} : YAML::load(string).symbolize_keys), page]
    end
end