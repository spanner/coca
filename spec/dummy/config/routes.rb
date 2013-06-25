Rails.application.routes.draw do

  mount Coca::Engine => "/coca"
  devise_for :users, :module => :devise

end
