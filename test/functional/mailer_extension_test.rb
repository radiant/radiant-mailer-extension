require File.dirname(__FILE__) + '/../test_helper'

class MailerExtensionTest < Test::Unit::TestCase
  
  # Replace this with your real tests.
  def test_this_extension
    flunk
  end
  
  def test_initialization
    assert_equal RADIANT_ROOT + '/vendor/extensions/mailer', MailerExtension.root
    assert_equal 'Mailer', MailerExtension.extension_name
  end
  
end
