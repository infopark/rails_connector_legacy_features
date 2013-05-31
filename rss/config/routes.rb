Rails.application.routes.draw do
  match 'rss', :to => 'rss#index', :format => "rss"
end
