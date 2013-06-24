class User < ActiveRecord::Base

  attr_accessible :uid, :authentication_token, :email, :password, :password_confirmation, :permissions
  devise :database_authenticatable,
         :token_authenticatable,
         :cocable

  before_create :ensure_authentication_token  # provided by devise
  before_create :ensure_uid

  ## Coca package
  #
  # This is returned to coca slave applications when authentication is found here.
  
  def serializable_hash(options={})
    {
      uid: uid,
      name: name,
      authentication_token: authentication_token
    }
  end
  
protected

  def ensure_uid
    self.uid ||= SecureRandom.uuid
  end

end
