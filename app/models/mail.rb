class Mail
  attr_reader :page, :config, :data, :leave_blank, :errors

  def initialize(page, config, data)
    @page, @config, @data = page, config.with_indifferent_access, data
    @required = required_fields
    @leave_blank = leave_blank_field
    @errors = {}
  end

  def self.valid_config?(config)
    config_errors(config).empty?
  end
  
  def self.config_errors(config)
    config_errors = {}
    %w(recipients from).each do |required_field|
      if config[required_field].blank? and config["#{required_field}_field"].blank?
        config_errors[required_field] = "is required"
      end
    end
    config_errors
  end
  
  def self.config_error_messages(config)
    config_errors(config).collect do |field, message|
      "'#{field}' #{message}"
    end.to_sentence
  end

  def valid?
    unless defined?(@valid)
      @valid = true
      if recipients.blank? and !is_required_field?(config[:recipients_field])
        errors['form'] = 'Recipients are required.'
        @valid = false
      end

      if recipients.any?{|e| !valid_email?(e)}
        errors['form'] = 'Recipients are invalid.'
        @valid = false
      end

      if from.blank? and !is_required_field?(config[:from_field])
        errors['form'] = 'From is required.'
        @valid = false
      end

      if !valid_email?(from)
        errors['form'] = 'From is invalid.'
        @valid = false
      end

      if @required
        @required.each do |name, msg|
          if "as_email" == msg
            unless valid_email?(data[name])
              errors[name] = "invalid email address."
              @valid = false
            end
          elsif m = msg.match(/\/(.*)\//)
            regex = Regexp.new(m[1])
            unless data[name] =~ regex
              errors[name] = "doesn't match regex (#{m[1]})"
              @valid = false
            end
          else
            if data[name].blank?
              errors[name] = ((msg.blank? || %w(1 true required not_blank).include?(msg)) ? "is required." : msg)
              @valid = false
            end
          end
        end
      end
      
      if leave_blank_field.present?
        name = @config[:leave_blank]
        unless @data[name].blank?
          errors[name] = "must be left blank."
          @valid = false
        end
      end
    end
    @valid
  end
  
  def from
    config[:from] || data[config[:from_field]]
  end

  def recipients
    config[:recipients] || data[config[:recipients_field]].split(/,/).collect{|e| e.strip}
  end

  def reply_to
    config[:reply_to] || data[config[:reply_to_field]]
  end

  def sender
    config[:sender]
  end

  def subject
    data[:subject] || config[:subject] || "Form Mail from #{page.request.host}"
  end
  
  def cc
    data[config[:cc_field]] || config[:cc] || ""
  end
  
  def files
    res = []
    data.each_value do |d|
      res << d if StringIO === d or Tempfile === d
    end
    res
  end
  
  def filesize_limit
    config[:filesize_limit] || 0
  end
  
  def plain_body
    return nil if not valid?
    @plain_body ||= (page.part( :email ) ? page.render_part( :email ) : page.render_part( :email_plain ))
  end
  
  def html_body
    return nil if not valid?
    @html_body = page.render_part( :email_html ) || nil
  end

  def send
    return false if not valid?

    if plain_body.blank? and html_body.blank?
      @plain_body = <<-EMAIL
The following information was posted:
#{data.to_hash.to_yaml}
      EMAIL
    end

    headers = { 'Reply-To' => reply_to || from }
    if sender
      headers['Return-Path'] = sender
      headers['Sender'] = sender
    end

    Mailer.deliver_generic_mail(
      :recipients => recipients,
      :from => from,
      :subject => subject,
      :plain_body => @plain_body,
      :html_body => @html_body,
      :cc => cc,
      :headers => headers,
      :files => files,
      :filesize_limit => filesize_limit
    )
    @sent = true
  rescue Exception => e
    errors['base'] = e.message
    @sent = false
  end

  def sent?
    @sent
  end

  protected

  def valid_email?(email)
    (email.blank? ? false : email =~ /^[^@]+@([^@.]+\.)[^@]+$/)
  end
  
  def is_required_field?(field_name)
    @required && @required.any? {|name,_| name == field_name}
  end
  
  def required_fields
    @config.has_key?(:required) ? @config[:required] : @data.delete(:required)
  end
  
  def leave_blank_field
    @config[:leave_blank] if @config.has_key?(:leave_blank)
  end
end