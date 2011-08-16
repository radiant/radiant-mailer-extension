require 'radiant-mailer-extension'
class MailerExtension < Radiant::Extension
  version RadiantMailerExtension::VERSION
  description RadiantMailerExtension::DESCRIPTION
  url RadiantMailerExtension::URL
  
  def activate
    Page.class_eval do
      include MailerTags
      include MailerProcess
    end
  end
end