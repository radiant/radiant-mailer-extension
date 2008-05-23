class MailerExtension < Radiant::Extension
  version "0.2"
  description "Provides support for email forms and generic mailing functionality."
  url "http://github.com/ntalbott/radiant-mailer-extension"

  define_routes do |map|
    map.resources :mail, :path_prefix => "/pages/:page_id", :controller => "mail"
  end

  def activate
    Page.send :include, MailerTags
  end
  
  def deactivate
  end
    
end