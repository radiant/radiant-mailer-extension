namespace :radiant do
  namespace :extensions do
    namespace :mailer do
      
      desc "Runs the migration of the Mailer extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          MailerExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          MailerExtension.migrator.migrate
        end
      end
    
      desc "Copies the Mailer extension assets to the public directory"
      task :update => :environment do
        FileUtils.cp MailerExtension.root + "/public/javascripts/email.js", RAILS_ROOT + "/public/javascripts"
      end
    end
  end
end