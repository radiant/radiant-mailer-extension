require 'action_mailer'
class MailerPage < Page
  TLDS = %w{com org net edu info mil gov biz ws}

  class MailerTagError < StandardError; end

  attr_reader :form_name, :form_conf, :form_error, :form_data, :tag_attr

  def config
    string = render_part(:config)
    unless string.empty?
      YAML::load(string)
    else
      {}
    end
  end

  # Page processing. If the page has posted-back, it will try to deliver the emails
  # and redirect to a different page, if specified.
  def process(request, response)
    @request, @response = request, response
    @form_name, @form_error = nil, nil
    if request.post?
      @form_name = request.parameters[:mailer_name]
      @form_data = request.parameters[:mailer]
      @form_conf = config['mailers'][form_name].symbolize_keys || {}
      # If there are recipients defined, send email...
      if form_conf.has_key? :recipients
        if send_mail and form_conf.has_key? :redirect_to
          response.redirect(form_conf[:redirect_to], "302 Found")
        else
          super(request, response)
        end
      else
        @form_error = "Email wasn't sent because no recipients are defined"
        super(request, response)
      end
    else
      super(request, response)
    end
  end

  # We need to process the page everytime, so that we can send the email!
  def cache?
    false
  end

  # Mailer Tags:

    desc %{ All mailer-related tags live inside this one. }
    tag "mailer" do |tag|
      tag.expand
    end

    desc %{
    Generates a form for submitting email.  The 'name' attribute is required
    and should correspond with configuration given in the 'config' part/tab.

    Usage:
    <pre><code>  <r:mailer:form name="contact">...</r:mailer:form></code></pre>}
    tag "mailer:form" do |tag|
      @tag_attr = { :class=>get_class_name('form') }.update( tag.attr.symbolize_keys )
      raise_error_if_name_missing 'mailer:form'
      # Build the html form tag...
      results =  %Q(<form action="#{ url }" method="post" class="#{ tag_attr[:class] }" enctype="multipart/form-data">)
      results << %Q(<div><input type="hidden" name="mailer_name" value="#{ tag_attr[:name] }" /></div>)
      results << %Q(<div class="mailer-error">#{form_error}</div>) if form_error
      results << tag.expand
      results << %Q(</form>)
    end

    # Build tags for all of the <input /> tags...
    %w(text password file submit reset checkbox radio hidden).each do |type|
      desc %{
      Renders a #{type} form control for a mailer form. #{"The 'name' attribute is required." unless %(submit reset).include? type}
      All unused attributes will be added as HTML attributes on the resulting tag.}
      tag "mailer:#{type}" do |tag|
        @tag_attr = tag.attr.symbolize_keys
        raise_error_if_name_missing "mailer:#{type}" unless %(submit reset).include? type
        input_tag_html( type )
      end
    end

    desc %{
    Renders a @<select>...</select>@ tag for a mailer form.  The 'name' attribute is required.  @<r:option />@ tags may be nested
    inside the tag to automatically generate options.
    }
    tag 'mailer:select' do |tag|
      @tag_attr = { :id=>tag.attr['name'], :class=>get_class_name('select'), :size=>'1' }.update( tag.attr.symbolize_keys )
      raise_error_if_name_missing "mailer:select"
      tag.locals.parent_tag_name = tag_attr[:name]
      tag.locals.parent_tag_type = 'select'
      results =  %Q(<select name="mailer[#{tag_attr[:name]}]" #{add_attrs_to("")}>)
      results << tag.expand
      results << "</select>"
    end

    desc %{
    Renders a <textarea>...</textarea> tag for a mailer form. The `name' attribute is required. }
    tag 'mailer:textarea' do |tag|
      @tag_attr = { :id=>tag.attr['name'], :class=>get_class_name('textarea'), :rows=>'5', :cols=>'35' }.update( tag.attr.symbolize_keys )
      raise_error_if_name_missing "mailer:textarea"
      results =  %Q(<textarea name="mailer[#{tag_attr[:name]}]" #{add_attrs_to("")}>)
      results << tag.expand
      results << "</textarea>"
    end

    desc %{
    Renders a series of @<input type="radio" .../>@ tags for a mailer form.  The 'name' attribute is required.
    Nested @<r:option />@ tags will generate individual radio buttons with corresponding values. }
    tag 'mailer:radiogroup' do |tag|
      @tag_attr = tag.attr.symbolize_keys
      raise_error_if_name_missing "mailer:radiogroup"
      tag.locals.parent_tag_name = tag_attr[:name]
      tag.locals.parent_tag_type = 'radiogroup'
      tag.expand
    end

    desc %{ Renders an @<option/>@ tag if the parent is a
    @<r:mailer:select>...</r:mailer:select>@ tag, an @<input type="radio"/>@ tag if
    the parent is a @<r:mailer:radiogroup>...</r:mailer:radiogroup>@ }
    tag 'mailer:option' do |tag|
      @tag_attr = tag.attr.symbolize_keys
      raise_error_if_name_missing "mailer:option"
      result = ""
      if tag.locals.parent_tag_type == 'select'
        result << %Q|<option value="#{tag_attr.delete(:value) || tag_attr[:name]}" #{add_attrs_to("")}>#{tag_attr[:name]}</option>|
      elsif tag.locals.parent_tag_type == 'radiogroup'
        tag.globals.option_count = tag.globals.option_count.nil? ? 1 : tag.globals.option_count += 1
        options = tag_attr.clone.update({
          :id => "#{tag.locals.parent_tag_name}_#{tag.globals.option_count}",
          :value => tag_attr.delete(:value) || tag_attr[:name],
          :name => tag.locals.parent_tag_name
        })
        result << %Q|<label for="#{options[:id]}">|
        result << input_tag_html( 'radio', options )
        result << %Q|<span>#{tag_attr[:name]}</span></label>|
      end
    end

    desc %{
    Renders an obfuscated email address @<option />@ tag
    using the email.js file. Use nested @<r:address>...</r:address>@ to specify the email
    address and @<r:label>...</r:label>@ to specify what the content of the tag should be. }
    tag 'mailer:email_option' do |tag|
      hash = tag.locals.params = {}
      contents = tag.expand
      address = hash['address'].blank? ? contents : hash['address']
      label = hash['label']
      if address =~ /([\w.%-]+)@([\w.-]+)\.([A-z]{2,4})/
        user, domain, tld = $1, $2, $3
        tld_num = TLDS.index(tld)
        unless label.blank?
        %{<script type="text/javascript">
              // <![CDATA[
              mail4('#{user}', '#{domain}', #{tld_num}, "#{label}");
              // ]]>
              </script>
        }
        else
        %{<script type="text/javascript">
              // <![CDATA[
              mail4('#{user}', '#{domain}', #{tld_num}, '#{user}');
              // ]]>
              </script>
        }
        end
      end
    end

    tag "mailer:email_option:label" do |tag|
      tag.locals.params['label'] = tag.expand.strip
    end

    tag "mailer:email_option:address" do |tag|
      tag.locals.params['address'] = tag.expand.strip
    end


    desc %{
    Renders the value of a datum submitted via a mailer form.  Used in the 'email', 'email_html', and
    'config' parts to generate the resulting email. }
    tag 'mailer:get' do |tag|
      name = tag.attr['name']
      if name
        form_data[name].is_a?(Array) ? form_data[name].to_sentence : form_data[name]
      else
        form_data.to_hash.to_yaml.to_s
      end
    end

protected

  # Since several form tags use the <input type="X" /> format, let's do that work in one place
  def input_tag_html(type, opts=tag_attr)
    options = { :id => tag_attr[:name], :value => "", :class=>get_class_name(type) }.update(opts)
    results =  %Q(<input type="#{type}" )
    results << %Q(name="mailer[#{options[:name]}]" ) if tag_attr[:name]
    results << "#{add_attrs_to("", options)}/>"
  end

  def add_attrs_to(results, tag_attrs=tag_attr)
    # Well, turns out I stringify the keys so I can sort them so I can test the tag output
    tag_attrs.stringify_keys.sort.each do |name, value|
      results << %Q(#{name.to_s}="#{value.to_s}" ) unless name == 'name'
    end
    results
  end

  # Get the default css class based on type
  def get_class_name(type, class_name=nil)
    class_name = 'mailer-form' if class_name.nil? and %(form).include? type
    class_name = 'mailer-field' if class_name.nil? and %(text password file select textarea).include? type
    class_name = 'mailer-button' if class_name.nil? and %(submit reset).include? type
    class_name = 'mailer-option' if class_name.nil? and %(checkbox radio).include? type
    class_name
  end

  # Raises a 'name missing' tag error
  def raise_name_error(tag_name)
    raise MailerTagError.new( "`#{tag_name}' tag requires a `name' attribute" )
  end
  def raise_error_if_name_missing(tag_name)
    raise_name_error( tag_name ) if tag_attr[:name].nil? or tag_attr[:name].empty?
  end

  # Does the work of actually sending the emails
  def send_mail()
    begin
      # Data defined in config part
      recipients = form_conf[:recipients]
      from = form_data[form_conf[:from_field]] || form_conf[:from] || "no-reply@#{request.host}"
      reply_to = form_data[form_conf[:reply_to_field]] || form_conf[:reply_to] || from
      # Render the email templates from page parts
      plain_body = part( :email ) ? render_part( :email ) : render_part( :email_plain )
      html_body = render_part( :email_html ) || nil
      # If we haven't defined any kind of mail template, use a default text one.
      if (plain_body.nil? or plain_body.empty?) and (html_body.nil? or html_body.empty?)
        plain_body = <<-EMAIL
The following information was posted:
#{form_data.to_hash.to_yaml}
        EMAIL
      end
      # Since we can't have a subclass of ActionMailer in our behavior file,
      # We add a generic mailer method to the ActionMailer::Base clase.
      # Is this a hack? Yes. Does it work? Yes.
      ActionMailer::Base.module_eval( <<-CODE ) unless ActionMailer::Base.respond_to? 'generic_mailer'
          def generic_mailer(options)
            @recipients = options[:recipients]
            @from = options[:from] || ""
            @cc = options[:cc] || ""
            @bcc = options[:bcc] || ""
            @subject = options[:subject] || ""
            @headers = options[:headers] || {}
            @charset = options[:charset] || "utf-8"
            @content_type = "multipart/alternative"
              if options.has_key? :plain_body
                part :content_type => "text/plain", :body => (options[:plain_body] || "")
              end
              if options.has_key? :html_body and !options[:html_body].blank?
                part :content_type => "text/html", :body => (options[:html_body] || "")
              end
          end
      CODE
      # Now deliver mail using our new generic_mail method
      ActionMailer::Base.deliver_generic_mailer(
        :recipients => recipients,
        :from => from,
        :subject => form_data[:subject] || form_conf[:subject] || "Form Mail from #{request.host}",
        :plain_body => plain_body,
        :html_body => html_body,
        :cc => form_data[form_conf[:cc_field]] || form_conf[:cc] || "",
        :headers => { 'Reply-To' => reply_to }
      )
    rescue
      @form_error = "Error encountered while trying to send email. #{$!}"
      return false
    end
    true
  end

end

