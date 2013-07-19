Rails.application.routes.draw do
  namespace "coca" do
    api :version => 1 do
      post "/check" => "authentications#show", :as => :check
    end
  end
end
