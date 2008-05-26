class MailController < ApplicationController

  no_login_required
  skip_before_filter :verify_authenticity_token  

  def create
    page = Page.find(params[:page_id])
    page.request, page.response = request, response

    config = config(page)

    mail = Mail.new(page, config, params[:mailer])
    page.last_mail = mail

    if mail.send
      redirect_to (config[:redirect_to] || "#{page.url}#mail_sent")
    else
      render :text => page.render
    end
  end
  
  private

  def config(page)
    string = page.render_part(:mailer)
    (string.empty? ? {} : YAML::load(string).symbolize_keys)
  end

end