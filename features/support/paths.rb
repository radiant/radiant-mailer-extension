module NavigationHelpers
  def path_to(page_name)
    case page_name
    
    when /the welcome page/
      admin_path
    when /the contact page/
      '/contact'
    when /the thank you page/
      '/contact/thank-you'
    
    # Add more page name => path mappings here
    
    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in features/support/paths.rb"
    end
  end
end

World(NavigationHelpers)