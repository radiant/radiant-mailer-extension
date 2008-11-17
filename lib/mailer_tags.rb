module MailerTags
  include Radiant::Taggable

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
    results << %(<form action="#{action}" method="post" enctype="multipart/form-data" #{mailer_attrs(tag)}>)
    results <<   tag.expand
    results << %(</form>)
    results << %(
<script type="text/javascript">
  function disableSubmitButtons()
  {
    var buttons = document.getElementsByName("mailer[mailer-form-button]");
    for( var idx = 0; idx < buttons.length; idx++ )
    {
      buttons[idx].disabled = true;
    }
  }
  function showSubmitPlaceholder()
  {
    var submitplaceholder = document.getElementById("submit-placeholder-part");
    if (submitplaceholder != null)
    {
      submitplaceholder.style.display="";
    }
  }
</script>)
  end

  desc %{
    Outputs a bit of javascript that will cause the enclosed content
    to be displayed when mail is successfully sent.}
  tag "mailer:if_success" do |tag|
    tag.expand if tag.locals.page.last_mail && tag.locals.page.last_mail.sent?
  end

  %w(text password reset checkbox radio hidden file).each do |type|
    desc %{
      Renders a #{type} input tag for a mailer form. The 'name' attribute is required.}
    tag "mailer:#{type}" do |tag|
      raise_error_if_name_missing "mailer:#{type}", tag.attr
      value = (prior_value(tag) || tag.attr['value'])
      result = [%(<input type="#{type}" value="#{value}" #{mailer_attrs(tag)} />)]
      add_required(result, tag)
    end
  end
  
  %w(submit image).each do |type|
    desc %{
      Renders a #{type} input tag for a mailer form.}
    tag "mailer:#{type}" do |tag|
      value = tag.attr['value'] || tag.attr['name']
      tag.attr.merge!("name" => "mailer-form-button")
      result = [%(<input onclick="disableSubmitButtons(); showSubmitPlaceholder();" type="#{type}" value="#{value}" #{mailer_attrs(tag)} />)]
    end
  end

  desc %{
    Renders a hidden div containing the contents of the submit_placeholder page part. The
    div will be shown when a user submits a mailer form.
  }
  tag "mailer:submit_placeholder" do |tag|
    if part(:submit_placeholder)
      results = %Q(<div id="submit-placeholder-part" style="display:none">)
      results << render_part(:submit_placeholder)
      results << %Q(</div>)
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
    Renders a <textarea>...</textarea> tag for a mailer form. The `name' attribute is required. }
  tag 'mailer:textarea' do |tag|
    raise_error_if_name_missing "mailer:textarea", tag.attr
    result =  [%(<textarea #{mailer_attrs(tag, 'rows' => '5', 'cols' => '35')}>)]
    result << (prior_value(tag) || tag.expand)
    result << "</textarea>"
    add_required(result, tag)
  end

  %{
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
      %(<input type="radio" value="#{value}"#{%( checked="checked") if selected} #{mailer_attrs(tag)} />)
    end
  end

  desc %{
    Renders the value of a datum submitted via a mailer form.  Used in the 'email', 'email_html', and
    'mailer' parts to generate the resulting email. }
  tag 'mailer:get' do |tag|
    name = tag.attr['name']
    mail = tag.locals.page.last_mail
    if name
      if mail.data[name].is_a?(Array)
        mail.data[name].map{ |d| d.respond_to?(:original_filename) ? d.original_filename : d.to_s }.to_sentence
      elsif mail.data[name].respond_to?(:original_filename)
        mail.data[name].original_filename
      else
        mail.data[name]
      end
    else
      mail.data.to_hash.to_yaml.to_s
    end
  end

  desc %{
    Renders the contained block if a named datum was submitted via a mailer form.  Used in the 'email', 'email_html' and 'mailer' parts
    to generate the resulting email.
  }
  tag 'mailer:if_value' do |tag|
    name = tag.attr['name']
    eq = tag.attr['equals']
    mail = tag.locals.page.last_mail || tag.globals.page.last_mail
    tag.expand if name && mail.data[name] && (eq.blank? || eq == mail.data[name])
  end

  def prior_value(tag, tag_name=tag.attr['name'])
    if mail = tag.locals.page.last_mail
      mail.data[tag_name] unless StringIO === mail.data[tag_name] or
        Tempfile === mail.data[tag_name]
    else
      nil
    end
  end

  def mailer_attrs(tag, extras={})
    attrs = {
      'id' => tag.attr['name'],
      'class' => nil,
      'size' => nil}.merge(extras)
    result = attrs.collect do |k,v|
      v = (tag.attr[k] || v)
      next if v.blank?
      %(#{k}="#{v}")
    end.reject{|e| e.blank?}
    result << %(name="mailer[#{tag.attr['name']}]") unless tag.attr['name'].blank?
    result.join(' ')
  end

  def add_required(result, tag)
    result << %(<input type="hidden" name="mailer[required][#{tag.attr['name']}]" value="#{tag.attr['required']}" />) if tag.attr['required']
    result
  end

  def raise_error_if_name_missing(tag_name, tag_attr)
    raise "`#{tag_name}' tag requires a `name' attribute" if tag_attr['name'].blank?
  end
end