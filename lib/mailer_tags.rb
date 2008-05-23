module MailerTags
  include Radiant::Taggable
  
  TLDS = %w{com org net edu info mil gov biz ws}

  desc %{ All mailer-related tags live inside this one. }
  tag "mailer" do |tag|
    tag.expand
  end

  desc %{
    Generates a form for submitting email.

    Usage:
    <pre><code>  <r:mailer:form name="contact">...</r:mailer:form></code></pre>}
  tag "mailer:form" do |tag|
    tag_attr = { :class=>get_class_name('form') }.update( tag.attr.symbolize_keys )
    results =  %Q(<form action="/pages/#{tag.locals.page.id}/mail" method="post" class="#{ tag_attr[:class] }" enctype="multipart/form-data">)
    results << tag.expand
    results << %Q(</form>)
  end

  # Build tags for all of the <input /> tags...
  %w(text password file checkbox radio hidden).each do |type|
    desc %{
    Renders a #{type} form control for a mailer form. #{"The 'name' attribute is required." unless %(submit reset).include? type}
    All unused attributes will be added as HTML attributes on the resulting tag.}
    tag "mailer:#{type}" do |tag|
      tag_attr = tag.attr.symbolize_keys
      raise_error_if_name_missing "mailer:#{type}", tag_attr
      input_tag_html( type, tag_attr )
    end
  end

  desc %{
  Renders a @<select>...</select>@ tag for a mailer form.  The 'name' attribute is required.  @<r:option />@ tags may be nested
  inside the tag to automatically generate options.
  }
  tag 'mailer:select' do |tag|
    tag_attr = { :id=>tag.attr['name'], :class=>get_class_name('select'), :size=>'1' }.update( tag.attr.symbolize_keys )
    raise_error_if_name_missing "mailer:select", tag_attr
    tag.locals.parent_tag_name = tag_attr[:name]
    tag.locals.parent_tag_type = 'select'
    results =  %Q(<select name="mailer[#{tag_attr[:name]}]" #{add_attrs_to("", tag_attr)}>)
    results << tag.expand
    results << "</select>"
  end

  desc %{
  Renders a <textarea>...</textarea> tag for a mailer form. The `name' attribute is required. }
  tag 'mailer:textarea' do |tag|
    tag_attr = { :id=>tag.attr['name'], :class=>get_class_name('textarea'), :rows=>'5', :cols=>'35' }.update( tag.attr.symbolize_keys )
    raise_error_if_name_missing "mailer:textarea", tag_attr
    results =  %Q(<textarea name="mailer[#{tag_attr[:name]}]" #{add_attrs_to("", tag_attr)}>)
    results << tag.expand
    results << "</textarea>"
  end

  %{
  Renders a series of @<input type="radio" .../>@ tags for a mailer form.  The 'name' attribute is required.
  Nested @<r:option />@ tags will generate individual radio buttons with corresponding values. }
  tag 'mailer:radiogroup' do |tag|
    tag_attr = tag.attr.symbolize_keys
    raise_error_if_name_missing "mailer:radiogroup", tag_attr
    tag.locals.parent_tag_name = tag_attr[:name]
    tag.locals.parent_tag_type = 'radiogroup'
    tag.expand
  end

  desc %{ Renders an @<option/>@ tag if the parent is a
  @<r:mailer:select>...</r:mailer:select>@ tag, an @<input type="radio"/>@ tag if
  the parent is a @<r:mailer:radiogroup>...</r:mailer:radiogroup>@ }
  tag 'mailer:option' do |tag|
    tag_attr = tag.attr.symbolize_keys
    raise_error_if_name_missing "mailer:option", tag_attr
    result = ""
    if tag.locals.parent_tag_type == 'select'
      result << %Q|<option value="#{tag_attr.delete(:value) || tag_attr[:name]}" #{add_attrs_to("", tag_attr)}>#{tag_attr[:name]}</option>|
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
  'mailer' parts to generate the resulting email. }
  tag 'mailer:get' do |tag|
    name = tag.attr['name']
    if name
      form_data[name].is_a?(Array) ? form_data[name].to_sentence : form_data[name]
    else
      form_data.to_hash.to_yaml.to_s
    end
  end

  # Since several form tags use the <input type="X" /> format, let's do that work in one place
  def input_tag_html(type, opts)
    options = { :id => opts[:name], :value => "", :class=>get_class_name(type) }.update(opts)
    results =  %Q(<input type="#{type}" )
    results << %Q(name="mailer[#{options[:name]}]" ) if opts[:name]
    results << "#{add_attrs_to("", opts)}/>"
  end

  def add_attrs_to(results, tag_attrs)
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
    raise "`#{tag_name}' tag requires a `name' attribute"
  end
  def raise_error_if_name_missing(tag_name, tag_attr)
    raise_name_error( tag_name ) if tag_attr[:name].nil? or tag_attr[:name].empty?
  end
end