Rails.application.routes.draw do
  namespace "coca" do
    match "/check/:scope" => "authentications#show", as: :check_scope, via: [:get, :post], defaults: {format: "json"}
    match "/check" => "authentications#show", as: :check, via: [:get, :post], defaults: {format: "json"}
  end
end
