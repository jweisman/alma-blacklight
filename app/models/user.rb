class User < ActiveRecord::Base

  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable

  # devise :database_authenticatable, :registerable,
  #       :recoverable, :rememberable, :trackable, :validatable

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    name
  end

  def self.from_jwt(token)
    where(uid: token["id"]).first_or_initialize.tap do |user|
      user.uid = token["id"]
      user.name = token["name"]
      user.email = token["email"]
      user.provider = token["provider"]
      user.save!
    end  
  end

  def self.from_alma(alma_user)
    where(id: alma_user['primary_id']).first_or_initialize.tap do |user|
      user.uid = alma_user['primary_id']
      user.name = alma_user["first_name"] + ' ' + alma_user["last_name"]
      user.email = alma_user["contact_info"]["email"][0]["email_address"]
      user.save!
    end
  end

end
