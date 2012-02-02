namespace :radiant do
  namespace :extensions do
    namespace :mailer do
      
      desc "Runs the migration of the Mailer extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          MailerExtension.migrator.migrate(ENV["VERSION"].to_i)
          Rake::Task['db:schema:dump'].invoke
        else
          MailerExtension.migrator.migrate
          Rake::Task['db:schema:dump'].invoke
        end
      end
    end
  end
end