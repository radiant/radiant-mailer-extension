module MailerTags
  include Radiant::Taggable
  include ActionView::Helpers::DateHelper

  def config
    @config ||= begin
      page = self
      until page.part(:mailer) or (not page.parent)
        page = page.parent
      end
      string = page.render_part(:mailer)
      (string.empty? ? {} : YAML::load(string))
    end
  end

  desc %{ All mailer-related tags live inside this one. }
  tag "mailer" do |tag|
    if Mail.valid_config?(config)
      tag.expand
    else
      "Mailer config is not valid (see Mailer.valid_config?)"
    end
  end

  desc %{
    Will expand if and only if there is an error with the last mail.

    If you specify the "on" attribute, it will only expand if there
    is an error on the named attribute, and will make the error
    message available to the mailer:error:message tag.}
  tag "mailer:if_error" do |tag|
    if mail = tag.locals.page.last_mail
      if on = tag.attr['on']
        if error = mail.errors[on]
          tag.locals.error_message = error
          tag.expand
        end
      else
        unless mail.valid?
          tag.expand
        end
      end
    end
  end

  desc %{
    Will expand if and only if there is NO error with the last mail.

    If you specify the "on" attribute, it will only expand if there
    is NO error on the named attribute.}
  tag "mailer:unless_error" do |tag|
    if mail = tag.locals.page.last_mail
      if on = tag.attr['on']
        unless mail.errors[on]
          tag.expand
        end
      else
        if mail.valid?
          tag.expand
        end
      end
    end
  end

  desc %{Outputs the error message.}
  tag "mailer:if_error:message" do |tag|
    tag.locals.error_message
  end

  desc %{
    Generates a form for submitting email.

    Usage:
    <pre><code>  <r:mailer:form>...</r:mailer:form></code></pre>}
  tag "mailer:form" do |tag|
    tag.attr['id'] ||= 'mailer'
    results = []
    action = Radiant::Config['mailer.post_to_page?'] ? tag.locals.page.url : "/pages/#{tag.locals.page.id}/mail##{tag.attr['id']}"
    results << %(<form action="#{action}" method="post" #{mailer_attrs(tag)}>)
    results <<   tag.expand
    results << %(</form>)
  end

  desc %{
    Outputs a bit of javascript that will cause the enclosed content
    to be displayed when mail is successfully sent.}
  tag "mailer:if_success" do |tag|
    tag.expand if tag.locals.page.last_mail && tag.locals.page.last_mail.sent?
  end

  %w(checkbox date datetime datetime-local email hidden month number radio range tel text time url week).each do |type|
    desc %{
      Renders a #{type} input tag for a mailer form. The 'name' attribute is required.}
    tag "mailer:#{type}" do |tag|
      raise_error_if_name_missing "mailer:#{type}", tag.attr
      value = (prior_value(tag) || tag.attr['value'])
      result = [%(<input type="#{type}" value="#{value}" #{mailer_attrs(tag)}>)]
      add_required(result, tag)
    end
  end

  desc %{
    Renders a @<select>...</select>@ tag for a mailer form.  The 'name' attribute is required.
    @<r:option />@ tags may be nested inside the tag to automatically generate options.}
  tag 'mailer:select' do |tag|
    raise_error_if_name_missing "mailer:select", tag.attr
    tag.locals.parent_tag_name = tag.attr['name']
    tag.locals.parent_tag_type = 'select'
    result = [%Q(<select #{mailer_attrs(tag, 'size' => '1')}>)]
    result << tag.expand
    result << "</select>"
    add_required(result, tag)
  end

  desc %{
    Renders a <textarea>...</textarea> tag for a mailer form. The 'name' attribute is required. }
  tag 'mailer:textarea' do |tag|
    raise_error_if_name_missing "mailer:textarea", tag.attr
    result =  [%(<textarea #{mailer_attrs(tag, 'rows' => '5', 'cols' => '35')}>)]
    result << (prior_value(tag) || tag.expand)
    result << "</textarea>"
    add_required(result, tag)
  end

  desc %{
    Renders a series of @<input type="radio" .../>@ tags for a mailer form.  The 'name' attribute is required.
    Nested @<r:option />@ tags will generate individual radio buttons with corresponding values. }
  tag 'mailer:radiogroup' do |tag|
    raise_error_if_name_missing "mailer:radiogroup", tag.attr
    tag.locals.parent_tag_name = tag.attr['name']
    tag.locals.parent_tag_type = 'radiogroup'
    tag.expand
  end

  desc %{ Renders an @<option/>@ tag if the parent is a
    @<r:mailer:select>...</r:mailer:select>@ tag, an @<input type="radio"/>@ tag if
    the parent is a @<r:mailer:radiogroup>...</r:mailer:radiogroup>@ }
  tag 'mailer:option' do |tag|
    if tag.locals.parent_tag_type == 'radiogroup'
      tag.attr['name'] ||= tag.locals.parent_tag_name
    end
    value = (tag.attr['value'] || tag.expand)
    prev_value = prior_value(tag, tag.locals.parent_tag_name)
    checked = tag.attr.delete('selected') || tag.attr.delete('checked')
    selected = prev_value ? prev_value == value : checked

    if tag.locals.parent_tag_type == 'select'
      %(<option value="#{value}"#{%( selected="selected") if selected} #{mailer_attrs(tag)}>#{tag.expand}</option>)
    elsif tag.locals.parent_tag_type == 'radiogroup'
      %(<input type="radio" value="#{value}"#{%( checked="checked") if selected} #{mailer_attrs(tag)}>)
    end
  end
  
  desc %{
    Provides a mechanism to iterate over array datum submitted via a 
    mailer form. Used in the 'email', 'email_html', and 'mailer' parts to 
    generate the resulting email. May work OK nested, but this hasn't been 
    tested.
  }
  tag 'mailer:get_each' do |tag|
    name = tag.attr['name']
    mail = tag.locals.page.last_mail
    if tag.locals.mailer_element then
      ary=tag.locals.mailer_element
    else
      ary=mail.data[name]
    end
    result=[]
    return '' if ary.blank?

    case ary
      when Array
        ary.each_with_index do |element, idx|
          tag.locals.mailer_key=idx
          tag.locals.mailer_element = element
          result << tag.expand
        end
      else
        ary.each do |key, element|
          tag.locals.mailer_key=key
          tag.locals.mailer_element = element
          result << tag.expand
        end
    end
    result
  end
  
  desc %{ 
    Uses @ActionView::Helpers::DateHelper.date_select@ to render three select tags for date selection. 
  }
  tag 'mailer:date_select' do |tag|
    raise_error_if_name_missing "mailer:date_select", tag.attr
    name = tag.attr.delete('name')
    
    options = {}
    
    tag.attr.each do |k, v|
      if v =~ /(true|false)/
        options[k] = (v == 'true')
      elsif v =~ /\d+/
        options[k] = v.to_i
      elsif k == 'order'
        options[k] = v.split(',').map(&:strip).map(&:to_sym)
      else
        options[k] = v
      end
    end
    
    options.symbolize_keys!
    
    date_select('mailer', name, options)
  end

  desc %{
    Renders the value of a datum submitted via a mailer form.  Used in the 
    'email', 'email_html', and 'mailer' parts to generate the resulting email.
    When used within mailer:get_each it defaults to getting elements within 
    that array. 
  }
  tag 'mailer:get' do |tag|
    name = tag.attr['name']
    mail = tag.locals.page.last_mail
    if tag.locals.mailer_element then
      element = tag.locals.mailer_element
    else
      element = tag.locals.page.last_mail.data
    end
    if name
      format_mailer_data(element, name)
    else
      element.to_hash.to_yaml.to_s
    end
  end
    
  desc %{
    For use within a mailer:get_each to output the index/key for each element 
    of the hash. 
  }
  tag 'mailer:index' do |tag|
    tag.locals.mailer_key || nil
  end

  desc %{
    Renders the contained block if a named datum was submitted via a mailer 
    form.  Used in the 'email', 'email_html' and 'mailer' parts to generate 
    the resulting email.
  }
  tag 'mailer:if_value' do |tag|
    name = tag.attr['name']
    eq = tag.attr['equals']
    mail = tag.locals.page.last_mail || tag.globals.page.last_mail
    tag.expand if name && mail.data[name] && (eq.blank? || eq == mail.data[name])
  end
  
  def format_mailer_data(element, name)
    data = element[name]
    if Array === data
      data.to_sentence
    elsif date = detect_date(element, name)
      date
    else
      data
    end
  end
  
  def detect_date(mail, name)
    date_components = mail.select { |key, value| key =~ Regexp.new("#{name}\\(\\di\\)") }
    
    if date_components.length == 3
      date_values = date_components.sort { |a, b| a[0] <=> b[0] }.map { |v| v[1].to_i }
      return Date.new(*date_values)
    else
      return nil
    end
  end

  def prior_value(tag, tag_name=tag.attr['name'])
    if mail = tag.locals.page.last_mail
      mail.data[tag_name]
    else
      nil
    end
  end

  def mailer_attrs(tag, extras={})
    attrs = {
      'accept' => nil,
      'accesskey' => nil,
      'alt' => nil,
      'autocomplete' => nil,
      'autofocus' => nil,
      'checked' => nil,
      'class' => nil,
      'contextmenu' => nil,
      'dir' => nil,
      'disabled' => nil,
      'height' => nil,
      'hidden' => nil,
      'id' => tag.attr['name'],
      'lang' => nil,
      'max' => nil,
      'maxlength' => nil,
      'min' => nil,
      'pattern' => nil,
      'placeholder' => nil,
      'size' => nil,
      'spellcheck' => nil,
      'step' => nil,
      'style' => nil,
      'tabindex' => nil,
      'title' => nil,
      'width' => nil}.merge(extras)
    result = attrs.collect do |k,v|
      v = (tag.attr[k] || v)
      next if v.blank?
      %(#{k}="#{v}")
    end.reject{|e| e.blank?}
    result << %(name="mailer[#{tag.attr['name']}]") unless tag.attr['name'].blank?
    result.join(' ')
  end

  def add_required(result, tag)
    result << %(<input type="hidden" name="mailer[required][#{tag.attr['name']}]" value="#{tag.attr['required']}">) if tag.attr['required']
    result
  end

  def raise_error_if_name_missing(tag_name, tag_attr)
    raise "`#{tag_name}' tag requires a `name' attribute" if tag_attr['name'].blank?
  end
end