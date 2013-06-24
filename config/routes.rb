Rails.application.routes.draw do
  namespace "coca" do
    api :version => 1 do
      match "*scope" => "authentications#show"
    end
  end
end
