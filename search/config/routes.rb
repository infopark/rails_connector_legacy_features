Rails.application.routes.draw do
  match 'search', :to => 'search#search'
end
