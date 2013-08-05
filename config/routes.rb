Rails.application.routes.draw do
  namespace "coca" do
    post "/check" => "authentications#show", :as => :check
  end
end
