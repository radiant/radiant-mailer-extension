# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "radiant-mailer-extension"
Gem::Specification.new do |s|
  s.name = %q{radiant-mailer-extension}
  
  s.version     = RadiantMailerExtension::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = RadiantMailerExtension::AUTHORS
  s.email       = RadiantMailerExtension::EMAIL
  s.homepage    = RadiantMailerExtension::URL
  s.summary     = RadiantMailerExtension::SUMMARY
  s.description = RadiantMailerExtension::DESCRIPTION
    
  ignores = if File.exist?('.gitignore')
    File.read('.gitignore').split("\n").inject([]) {|a,p| a + Dir[p] }
  else
    []
  end
  s.files         = Dir['**/*'] - ignores
  s.test_files    = Dir['test/**/*','spec/**/*','features/**/*'] - ignores
  # s.executables   = Dir['bin/*'] - ignores
  s.require_paths = ["lib"]
  
  s.post_install_message = %{
  Add this to your radiant project with:
    config.gem 'radiant-mailer-extension', :version => '~>#{RadiantMailerExtension::VERSION}'
  }
end

