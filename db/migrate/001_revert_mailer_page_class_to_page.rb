class RevertMailerPageClassToPage < ActiveRecord::Migration
  def self.up
    # Leaving pages with MailerPage class_name if this model no longer exists would result in an error
    Page.update_all("class_name = 'Page'", "class_name = 'MailerPage'")
  end

  def self.down
    # Can not be reverted!
  end
end