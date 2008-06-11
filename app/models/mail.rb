class Mail
  attr_reader :page, :config, :data, :errors
  def initialize(page, config, data)
    @page, @config, @data = page, config, data
    @required = @data.delete(:required)
    @errors = {}
  end
  
  def valid?
    unless defined?(@valid)
      @valid = true
      if config[:recipients].blank?
        errors['form'] = 'Recipients are required.'
        @valid = false
      end
      
      if from.blank?
        errors['form'] = 'From is required.'
        @valid = false
      end
    
      if @required
        @required.each do |name,_|
          if data[name].blank?
            errors[name] = "is required."
            @valid = false
          end
        end
      end
    end
    @valid
  end
  
  def from
    config[:from] || data[config[:from_field]]
  end
  
  def send
    return false if not valid?

    recipients = config[:recipients]
    reply_to = data[config[:reply_to_field]] || config[:reply_to] || from

    plain_body = (page.part( :email ) ? page.render_part( :email ) : page.render_part( :email_plain ))
    html_body = page.render_part( :email_html ) || nil

    if plain_body.blank? and html_body.blank?
      plain_body = <<-EMAIL
The following information was posted:
#{data.to_hash.to_yaml}
      EMAIL
    end

    Mailer.deliver_generic_mail(
      :recipients => recipients,
      :from => from,
      :subject => data[:subject] || config[:subject] || "Form Mail from #{page.request.host}",
      :plain_body => plain_body,
      :html_body => html_body,
      :cc => data[config[:cc_field]] || config[:cc] || "",
      :headers => { 'Reply-To' => reply_to }
    )
  end
end