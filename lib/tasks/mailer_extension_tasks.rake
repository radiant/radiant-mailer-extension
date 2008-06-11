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
    end
  end
end