Rails.application.routes.draw do
  match 'comments/:action(/:id)', :to => 'comments', :as => "comment"
end
