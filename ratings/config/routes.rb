Rails.application.routes.draw do
  match 'ratings/:action/:id(/:score)', :to => 'ratings', :as => "ratings"
end
