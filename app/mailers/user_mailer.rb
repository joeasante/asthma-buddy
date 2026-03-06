# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    @verification_url = email_verification_url(token: @user.generate_token_for(:email_verification))
    mail(to: @user.email_address, subject: "Verify your email address — Asthma Buddy")
  end
end
