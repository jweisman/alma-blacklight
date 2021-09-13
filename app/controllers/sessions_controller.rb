require 'onelogin/ruby-saml'
require 'jwt'

class SessionsController < ApplicationController
  include Alma

  skip_before_filter :verify_authenticity_token

  def create
    redirect_to root_path and return if !params[:jwt] 

    decoded_token = 
      JWT.decode params[:jwt], 
      ENV['alma_auth_secret'], 
      true, 
      { :algorithm => 'HS256' }

    validate_user token["id"]
    redirect_to root_path  
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end

  def login
    redirect_to "https://#{ENV['alma']}.alma.exlibrisgroup.com/view/socialLogin?institutionCode=#{ENV['institution']}&backUrl=#{ENV['root_url']}/auth/jwt/callback"
  end

  def init_saml
    request = OneLogin::RubySaml::Authrequest.new
    redirect_to(request.create(saml_settings))
  end

  def consume_saml
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], :settings => saml_settings)
  
    # We validate the SAML Response and check if the user already exists in the system
    if response.is_valid?
        validate_user response.nameid
    else
      flash.now[:alert] = "Authentication failed"
      # List of errors is available in response.errors array
    end
    redirect_to root_path
  end

  private
  
  def validate_user(user_id) 
    # Confirm user exists in Alma
    if !valid_alma_user?(user_id)
      flash.now[:alert] = "Your user doesn't exist in Alma. (#{user.uid})"
    end  
  end

  def valid_alma_user?(user_id)
    begin
      user = Alma.get "/users/#{user_id}"
      User.from_alma(user)
      session[:user_id] = user["primary_id"]
      return true
    rescue RestClient::BadRequest => e
      if e.response.body.include? "401861" # user not found
        return false
      else
        raise e
      end
    end
  end

  def saml_settings
    idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
    # Returns OneLogin::RubySaml::Settings pre-populated with IdP metadata
    settings = idp_metadata_parser.parse_remote(ENV["SAML_METADATA_URL"])
  
    settings.assertion_consumer_service_url = "#{request.protocol}#{request.host_with_port}/saml/consume"
    settings.sp_entity_id                   = "#{request.protocol}#{request.host_with_port}/saml/metadata"
    settings.name_identifier_format         = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

    settings
  end

end