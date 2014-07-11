require 'radiant-mailer-extension'
class MailerExtension < Radiant::Extension
  version RadiantMailerExtension::VERSION
  description RadiantMailerExtension::DESCRIPTION
  url RadiantMailerExtension::URL
  
  # Backward compatibility for routes. 
  unless defined?(Radiant::Extension.extension_config)
    define_routes do |map|
      map.resources :mail, :path_prefix => "/pages/:page_id", :controller => "mail"
    end
  end
  
  def activate
    Page.class_eval do
      include MailerTags
      include MailerProcess
    end
  end
end