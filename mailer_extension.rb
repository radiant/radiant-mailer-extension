class MailerExtension < Radiant::Extension
  version "0.2"
  description "Provides support for email forms and generic mailing functionality."
  url "http://github.com/ntalbott/radiant-mailer-extension"

  define_routes do |map|
    map.resources :mail, :path_prefix => "/pages/:page_id", :controller => "mail"
  end

  def activate
    Page.class_eval do
      include MailerTags
      attr_accessor :last_mail
    end
  end
  
  def deactivate
  end
    
end