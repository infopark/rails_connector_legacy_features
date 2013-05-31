class ConfirmationMailer < ActionMailer::Base
  # @return [void]
  def reset_password(recipient, confirmation_url)
    @confirmation_url = confirmation_url
    mail(:to => recipient, :subject =>
        I18n.t("rails_connector.views.user.forgot_password_subject"))
  end

  # @return [void]
  def register_confirmation(recipient, confirmation_url)
    @confirmation_url = confirmation_url
    mail(:to => recipient, :subject =>
        I18n.t("rails_connector.views.user.register_password_confirmation_mail_subject"))
  end
end
