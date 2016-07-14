class SessionsController < ApplicationController
  include Alma
  require 'jwt'

  skip_before_filter :verify_authenticity_token, only: :create

  def create
    redirect_to root_path and return if !params[:jwt] 

    decoded_token = 
      JWT.decode params[:jwt], 
      ENV['alma_auth_secret'], 
      true, 
      { :algorithm => 'HS256' }

    user = User.from_jwt(decoded_token[0])

    # Confirm user exists in Alma
    if valid_alma_user?(user.uid)
      session[:user_id] = user.id
    else
      flash.now[:alert] = "Your user doesn't exist in Alma. (#{user.uid})"
    end  
    redirect_to root_path  
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end

  def login
    redirect_to "https://#{ENV['alma']}.alma.exlibrisgroup.com/view/socialLogin?institutionCode=#{ENV['institution']}&backUrl=#{ENV['root_url']}/auth/jwt/callback"
  end
  
  private
  
  def valid_alma_user?(user_id)
    begin
       user = Alma.get "/users/#{user_id}"
       return true
    rescue RestClient::BadRequest => e
      if e.response.body.include? "401861" # user not found
        return false
      else
        raise e
      end
    end
  end
end