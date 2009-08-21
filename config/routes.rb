ActionController::Routing::Routes.draw do |map|
  map.resources :messages, :member => { :quote => :get, :topic => :get, :bbcode => :get }
  map.resources :forums do |forum|
    forum.resources :topics, :member => { :show_new => :get }
  end
  map.resources :categories
  map.namespace :admin do |admin|
    admin.resources :categories
    admin.resources :forums
  end
end
