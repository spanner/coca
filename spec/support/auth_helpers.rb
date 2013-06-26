module AuthHelpers
  # for controller tests:

  def authenticate(user)
    if user
      request.env['warden'].stub(:authenticate! => user)
      request.env['warden'].stub(:authenticate => user)
      controller.stub :current_user => user
    else
      request.env['warden'].stub(:authenticate!).and_throw(:warden, {:scope => :user})
      request.env['warden'].stub(:authenticate => nil)
      controller.stub :current_user => nil
    end
  end

end
