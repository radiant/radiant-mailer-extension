# Sets up the Rails environment for Cucumber
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + '/../../../../../config/environment')
 
require 'cucumber/rails/world'
require 'cucumber/formatter/unicode' # Comment out this line if you don't want Cucumber Unicode support

require 'webrat'
 
Webrat.configure do |config|
  config.mode = :rails
end

require 'spec'
require 'email_spec/cucumber'

# Comment out the next two lines if you're not using RSpec's matchers (should / should_not) in your steps.
require 'cucumber/rails/rspec'
require 'webrat/core/matchers'
 
Cucumber::Rails::World.class_eval do
  include Dataset
  datasets_directory "#{RADIANT_ROOT}/spec/datasets"
  Dataset::Resolver.default = Dataset::DirectoryResolver.new("#{RADIANT_ROOT}/spec/datasets", File.dirname(__FILE__) + '/../datasets')
  self.datasets_database_dump_path = "#{Rails.root}/tmp/dataset"
  
  dataset :pages, :users, :mailer_page
end