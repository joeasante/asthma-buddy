# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  def new_signup(user)
    @user = user
    @admin_email = Rails.application.credentials.admin_email
    @admin_users_url = begin
      admin_users_url
    rescue NameError
      "/admin/users"
    end
    mail(to: @admin_email, subject: "New signup: #{user.email_address}")
  end
end
