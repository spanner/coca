Coca::Engine.routes.draw do

  get "/:scope" => "coca/authentications#check"

end
