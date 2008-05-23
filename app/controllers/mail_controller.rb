class MailController < ApplicationController

  no_login_required
  skip_before_filter :verify_authenticity_token  

  def create
    page = Page.find(params[:page_id])
    config = config(page)
    # If there are recipients defined, send email...
    if send_mail(page, config, params[:mailer])
      redirect_to (config[:redirect_to] || page.url)
    else
      page.request, page.response = request, response
      render :text => page.render
    end
  end
  
  private

  def send_mail(page, config, data)
    p :config => config, :data => data
    recipients = config[:recipients]
    from = data[config[:from_field]] || config[:from] || "no-reply@#{request.host}"
    reply_to = data[config[:reply_to_field]] || config[:reply_to] || from

    plain_body = page.part( :email ) ? page.render_part( :email ) : page.render_part( :email_plain )
    html_body = page.render_part( :email_html ) || nil

    if (plain_body.nil? or plain_body.empty?) and (html_body.nil? or html_body.empty?)
      plain_body = <<-EMAIL
The following information was posted:
#{data.to_hash.to_yaml}
      EMAIL
    end

    Mailer.deliver_generic_mail(
      :recipients => recipients,
      :from => from,
      :subject => data[:subject] || config[:subject] || "Form Mail from #{request.host}",
      :plain_body => plain_body,
      :html_body => html_body,
      :cc => data[config[:cc_field]] || config[:cc] || "",
      :headers => { 'Reply-To' => reply_to }
    )

    true
  end

  REQUIRED_CONFIG = %w(recipients)
  def config(page)
    string = page.render_part(:mailer)
    config = unless string.empty?
      YAML::load(string)
    else
      {}
    end
    missing = REQUIRED_CONFIG.reject{|e| config[e]}
    raise "Missing required config parts: #{missing.join(', ')}" unless missing.empty?
    config.symbolize_keys
  end

end