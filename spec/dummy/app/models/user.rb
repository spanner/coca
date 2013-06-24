class User < ActiveRecord::Base

  attr_accessible :uid, :authentication_token, :email, :password, :password_confirmation, :permissions
  devise :database_authenticatable,
         :token_authenticatable,
         :cocable

  # Current user is pushed into here to make it available in models
  # such as the UserActionObserver that sets ownership before save.
  #
  def self.current
    Thread.current[:user]
  end
  def self.current=(user)
    Thread.current[:user] = user
  end

  
  ## Coca package
  #
  # This is returned to coca slave applications when  authentication is given here.
  
  def serializable_hash(options={})
    {
      uid: uid,
      name: name,
      authentication_token: authentication_token
    }
  end
  
  def self.find_or_create_from_coca
    
  end
  
end
