# frozen_string_literal: true

class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    @token = user.generate_token_for(:password_reset)
    mail subject: "Reset your password — Asthma Buddy", to: user.email_address
  end
end
