class User < ActiveRecord::Base

  devise :database_authenticatable,
         :token_authenticatable,
         :cocable

  before_create :ensure_authentication_token
  before_create :ensure_uid

  ## Coca package
  #
  # This is returned to coca slave applications when authentication is found here.
  
  def as_json_for_coca(options={})
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
