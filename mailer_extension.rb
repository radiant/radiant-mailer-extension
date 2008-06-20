class MailerExtension < Radiant::Extension
  version "0.1"
  description "Provides a page type for email forms and generic mailing functionality. Based on Matt McCray's behavior."
  url "http://dev.radiantcms.org/svn/radiant/branches/mental/extensions/mailer/"

  def activate
     MailerPage
  end
  
  def deactivate
  end
    
end