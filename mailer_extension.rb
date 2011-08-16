class MailerExtension < Radiant::Extension
  version "1.0"
  description "Provides support for email forms and generic mailing functionality."
  url "http://github.com/radiant/radiant-mailer-extension"

  def activate
    Page.class_eval do
      include MailerTags
      include MailerProcess
    end
  end
end