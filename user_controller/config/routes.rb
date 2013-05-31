Rails.application.routes.draw do
  match 'login', :to => 'user#login'
  match 'logout', :to => 'user#logout'
  match 'user/:action', :to => 'user', :as => "user"
end
